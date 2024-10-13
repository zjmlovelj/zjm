# -*- coding:utf-8 -*-
__author__ = 'Andrew.Chen@Suncode'
__version__ = '0.1'

import re
import os
import subprocess
import threading
import datetime
from time import sleep
import time
from argparse import ArgumentParser



def timeStamp():
    current_time = "[ "+str(datetime.datetime.now())[:-7]+ " ]:\t"
    return current_time


def executeShellCMD(cmd):
    p = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    (output, err) = p.communicate()
    return output, err

def operatePlist(cmd,plist_file):
    cmd = '/usr/libexec/PlistBuddy -c \"'+cmd+'\" '+plist_file
    output, err = executeShellCMD(cmd)
    return output

def createDylibShortcut(path,fixtureType,vendorName):
    if os.path.exists(path+'/lib'+fixtureType+'Fixture.dylib'):
        cmd = 'rm '+path+'/lib'+fixtureType+'Fixture.dylib'
        content,err = executeShellCMD(cmd)
        log_file.write(timeStamp()+cmd+'\n'+content+'\n'+err)
    cmd = 'ln -s '+path+'/lib'+fixtureType+'Fixture_'+vendorName+'.dylib '+path+'/lib'+fixtureType+'Fixture.dylib'
    content,err = executeShellCMD(cmd)
    log_file.write(timeStamp()+cmd+'\n'+content+'\n'+err)
    return True

def IPPingCheck(ip_address):
    global log_file_lock
    global log_file
    cmd = "ping -c 1 "+ ip_address
    for i in range(5):
        content,err = executeShellCMD(cmd)
        with log_file_lock:
            log_file.write(timeStamp()+content)
        if content.find('100.0% packet loss') != -1 and i == 4:
            print 'ping ' + ip_address +' fail!'
            return False
        if content.find('1 packets received') != -1:
            break
        sleep(0.2)
    return True

def hostKeyVerfiy(console_str):
    result = re.match(r"offending\s*ecdsa\s*key\s*in\s*(.*)\:",console_str)
    if result is not None:
        cmd = "rm "+result.group(1)
        content,err = executeShellCMD(cmd)
        return True
    return False


def scp_file_to_remote(host_ip_address, user_name, password, local_path, target_path, port=22):
    scp_cmd = r"""
            expect -c "
            set timeout 300;
            spawn scp -P {port} {local_path} {username}@{host}:{target_path};
            expect {{
                \"*(yes/no)*\" {{ send "yes"\n; exp_continue }}
                \"*assword*\" {{ send {password}\n }}
            }} ;
            expect *\n;
            expect eof
            "
    """.format(username=user_name, password=password, host=host_ip_address,
               local_path=local_path, target_path=target_path,
               port=port)

    p = subprocess.Popen(scp_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    (output, err) = p.communicate()
    return output


def ssh_command_execute(host_ip_address, user_name, password, command):
    ssh_cmd = r"""
        expect -c "
        set timeout 60;
        spawn ssh {user}@{host} {command}
        expect {{
            \"*(yes/no)*\" {{ send "yes"\n; exp_continue }}
            \"*assword*\" {{ send {password}\n }}
        }} ;
        expect *\n;
        expect eof
        "
    """.format(user=user_name, host=host_ip_address, password=password, command=command)

    p = subprocess.Popen(ssh_cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    (output, err) = p.communicate()
    return output

def getLocalMixInfo(vendor, mixInfo):
    # stationType = operatePlist('Print :MixInfo:stationType',plist_file).replace("\n","").replace("\r","")
    # MixName = operatePlist('Print :MixInfo:'+vendor+':MixName',plist_file).replace("\n","").replace("\r","")
    # MixMD5 = operatePlist('Print :MixInfo:'+vendor+':MixMD5',plist_file).replace("\n","").replace("\r","")
    # MixSHA1 = operatePlist('Print :MixInfo:'+vendor+':MixSHA1',plist_file).replace("\n","").replace("\r","")
    # MixVersion = operatePlist('Print :MixInfo:'+vendor+':MixVersion',plist_file).replace("\n","").replace("\r","")
    try:
        stationType = mixInfo["stationType"]
        MixName = mixInfo[vendor]["MixName"]
        MixMD5 = mixInfo[vendor]["MixMD5"]
        MixSHA1 = mixInfo[vendor]["MixSHA1"]
        MixVersion = mixInfo[vendor]["MixVersion"]
        return stationType,MixName,MixMD5,MixSHA1,MixVersion
    except Exception :
        log_file.write(timeStamp()+"get mix info fail! :-(\n")


def get_xavier_mix_version(host_ip_address='169.254.1.32', username='root', passwd='123456'):
    addonVersion = "" 
    packageVersion = ""
    plVersion = ""
    fixtureType,vendorName , mixVer = "","" ,""
    if IPPingCheck(host_ip_address):
        versoion_file = '/mix/version.json'
        stdout = ssh_command_execute(host_ip_address, username, passwd, "cat " + versoion_file)
        if "No such file or directory" in stdout:
            raise Exception("%s is not exit" % versoion_file)
        if stdout is not None:
            if hostKeyVerfiy(stdout) == True:
                stdout = ssh_command_execute(host_ip_address, username, passwd, "cat " + versoion_file)
        version_info = eval(stdout[stdout.find('{'):stdout.find('}') + 1])
        for k in version_info:
            if 'Addon' in k:
                addonVersion = version_info[k]
                result = re.match(r"Addon_.+_(\w+)_(\w+)",k)
                if result is None:
                    raise Exception("match not fail")
                else:
                    fixtureType = result.group(1)
                    vendorName = result.group(2)
            if 'PACKAGE' in k:
                packageVersion = version_info[k]
            if 'PL_' in k:
                plVersion = version_info[k]
        if addonVersion is not None and packageVersion is not None and plVersion is not None:
            mixVer = addonVersion + "." + packageVersion + "." + plVersion
    return fixtureType,vendorName,mixVer


def checkLocalMixFWFile(local_mix_file_path,local_mix_fw_name,MixMD5,MixSHA1):
    files_list = os.listdir(local_mix_file_path)
    local_mix_file_name = ""
    for file in files_list:
        if file == local_mix_fw_name:
            local_mix_file_name = file
            print("%s mix file found in local." % local_mix_fw_name)
            break
    if local_mix_file_name == "":
        print("%s mix file dont found in local." % local_mix_fw_name)
        return False
    else:
        mix_file_fullPath = local_mix_file_path+local_mix_fw_name
        content,err = executeShellCMD("md5 "+mix_file_fullPath)
        md5_value = re.match(r'MD5.*= ([0-9a-f]+)', content)
        md5_value = md5_value.group(1)
        content,err = executeShellCMD("openssl sha1 "+mix_file_fullPath)
        sha1_value = re.match(r'SHA1.*= ([0-9a-f]+)', content)
        sha1_value = sha1_value.group(1)
        print("computed md5_value = %s " % md5_value)
        print("expected MixMD5 = %s " % MixMD5)
        print("computed sha1_value = %s " % sha1_value)
        print("expected MixSHA1 = %s " % MixSHA1)
        log_file.write(timeStamp()+"local Mix computed md5_value = %s " % md5_value+'\n')
        log_file.write(timeStamp()+"local Mix expect MixMD5 = %s " % MixMD5+'\n')
        log_file.write(timeStamp()+"local Mix computed sha1_value = %s " % sha1_value+'\n')
        log_file.write(timeStamp()+"local Mix expect MixSHA1 = %s " % MixSHA1+'\n')
        if MixMD5 == md5_value and sha1_value == MixSHA1:
            print("local mix file md5/sha1 check PASS.")
            log_file.write(timeStamp()+"local mix file md5/sha1 check PASS."+'\n\n')
            return True
        else:
            print("local mix file md5/sha1 check failed,dont update mix FW!")
            log_file.write(timeStamp()+"local mix file md5/sha1 check failed,dont update mix FW!"+'\n\n')
            return False



def get_remote_fw_md5(host_ip_address, user_username, passwd, file):
    stdout = ssh_command_execute(host_ip_address, user_username, passwd,
                                 "md5sum " + file)
    start_index = stdout.find('password:') + len('password:')
    return stdout[start_index + 3: start_index + 35]


def is_remote_and_local_fw_version_match(local_fw_abs_path, host_ip_address, user_username, passwd,localMixVersion):

    try:
        fixtureType,vendorName,remote_fw_version = get_xavier_mix_version(host_ip_address, user_username, passwd)
    except Exception:
        with log_file_lock:
            log_file.write(timeStamp()+"get (%s) xavier mix fw version fail! :-(\n" % (host_ip_address))
            #print "Connect to %s failed!" % host_ip_address
        return False
    #print local_fw_version, remote_fw_version
    if localMixVersion is not None and localMixVersion == remote_fw_version:
        with log_file_lock:
            log_file.write(timeStamp()+"ip is (%s), expected FW version: (%s) , Xavier FW version: (%s), no need to upgrade. :-)\n" %
                           (host_ip_address,localMixVersion, remote_fw_version))
        return True
    else:
        with log_file_lock:
            log_file.write(timeStamp()+"ip is (%s), expected FW version: (%s), Xavier FW version: (%s), will be upgraded to (%s).\n" %
                           (host_ip_address,localMixVersion,remote_fw_version,localMixVersion))
        return False


def get_fw_abs_path(local_fw_relative_path):
    os.chdir(os.path.dirname(local_fw_relative_path))
    local_fw_abs_path = os.getcwd() + '/'
    return local_fw_abs_path


def FWUpgrade(host_ip_address,local_fw_relative_path,MixName,localMixMD5,localMixSHA1,localMixVersion,mixFileUpdateTargetPath,username,password):
    local_fw_abs_path = get_fw_abs_path(local_fw_relative_path)

    global upgrade_failed_host_ip_address
    global thread_lock

    ret = True
    content =""
    if not is_remote_and_local_fw_version_match(local_fw_abs_path, host_ip_address,username,password,localMixVersion):
        retry = 2
        while retry > 0:
            retry -= 1
            ret1 = ssh_command_execute(host_ip_address,username,password, 'rm -rf ' + mixFileUpdateTargetPath + MixName)
            with log_file_lock:
                log_file.write(timeStamp()+ret1)           
            ret2 = scp_file_to_remote(host_ip_address,username,password, local_fw_abs_path + MixName, mixFileUpdateTargetPath)
            with log_file_lock:
                log_file.write(timeStamp()+ret2)
            remote_fw_md5 = get_remote_fw_md5(host_ip_address,username,password, mixFileUpdateTargetPath + MixName)
            if localMixMD5 == remote_fw_md5:
                ret3 = ssh_command_execute(host_ip_address,username,password, "reboot")
                print "^_^ Mix Upgrade is running, please wait for Xavier board upgrading...\n"
                with log_file_lock:
                    log_file.write(timeStamp()+" (%s) localMixMD5: %s == remote_fw_md5: %s " % (host_ip_address,localMixMD5,remote_fw_md5) +ret3+"\n^_^ Mix Upgrade is running, please wait for Xavier board upgrading...\n")
                break
        if retry <= 0:
            ssh_command_execute(host_ip_address,username,password, 'rm -rf ' + mixFileUpdateTargetPath + MixName)
            with thread_lock:
                upgrade_failed_host_ip_address += host_ip_address + '\n'
            with log_file_lock:
                log_file.write(timeStamp()+"host_ip_address:%s, scp FW to Xavier failed, please check!\n" % (host_ip_address))
            raise Exception("host_ip_address:%s, scp FW to Xavier failed, please check!\n" % (host_ip_address))
    else:
        ret = 'SAME'
        print " ("+host_ip_address + "), the version of expected and Xavier FW is the same:(%s), no need to upgrade. :-)\n" % localMixVersion
        log_file.write(timeStamp()+"the version of expected and Xavier FW is the same:(%s), no need to upgrade. :-)\n" % (localMixVersion))
    return ret

def mulptiChannelFWUpgrade(local_fw_relative_path,log_path,MixName,localMixMD5,localMixSHA1,localMixVersion,mixFileUpdateTargetPath,host_ip_address='169.254.1.32',username='root',password='123456'):

    threads_list = list()
    ip_index = host_ip_address.rfind('.')
    last_ip_num = int(host_ip_address[ip_index + 1:])


    threads_list.append(threading.Thread(target=FWUpgrade, args=(host_ip_address[:ip_index + 1] + '%s' % (last_ip_num), local_fw_relative_path,MixName,localMixMD5,localMixSHA1,localMixVersion,mixFileUpdateTargetPath,username,password)))
    try:
        [thread.start() for thread in threads_list]
        [thread.join() for thread in threads_list]
    except Exception:
        return upgrade_failed_host_ip_address
    return upgrade_failed_host_ip_address

def is_remote_fw_version_changed(host_ip_address, username, password, currentMixVer):
    ret = False
    fixtureType,vendorName,upgradedMixVer = get_xavier_mix_version(host_ip_address,username,password)
    if currentMixVer != upgradedMixVer:
        ret = True
    return ret

def is_fw_finished_upgrade(host_ip_address, local_fw_relative_path,localMixVersion,username,password, currentMixVer):
    os.chdir(os.path.dirname(local_fw_relative_path))
    local_fw_abs_path = os.getcwd() + '/'

    state = False
    start_time = time.time()
    while not state:
        try:
            state = is_remote_fw_version_changed(host_ip_address, username, password, currentMixVer)
            with log_file_lock:
                if state:
                    log_file.write(timeStamp()+"\n\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\nip address:%s, Xavier Mix FW check PASS! :-)\n~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~\n\n" % (host_ip_address))
        except Exception:
            pass
        sleep(2)
        current_time = time.time()
        if current_time - start_time > 600:
            print('the version of expected and Xavier FW is the same, local MIX version may be incorrect')
            log_file.write(timeStamp()+"the version of expected and Xavier FW is the same, local MIX version may be incorrect\n")
            break

    match = is_remote_and_local_fw_version_match(local_fw_abs_path, host_ip_address, username, password,localMixVersion)
    if match:
        print('FW upgrade done!')
        log_file.write(timeStamp()+"FW upgrade done\n")
    else:
        print('local MIX version may be incorrect!')
        log_file.write(timeStamp()+"local MIX version may be incorrect\n")

    return True


def waitForMixFWupdate(local_fw_relative_path,localMixVersion,host_ip_address='169.254.1.32',username='root',password='123456',currentMixVer='1.0.0'):

    threads_list = list()
    ip_index = host_ip_address.rfind('.')
    last_ip_num = int(host_ip_address[ip_index + 1:])

    threads_list.append(threading.Thread(target=is_fw_finished_upgrade, args=(host_ip_address[:ip_index + 1] + '%s' % (last_ip_num), local_fw_relative_path,localMixVersion,username,password,currentMixVer)))
    [thread.start() for thread in threads_list]
    [thread.join() for thread in threads_list]

    return True


if __name__ == '__main__':
    current_dir = os.path.dirname(os.path.realpath(__file__))
    baseIPAddress = "169.254.1.32"
    username = 'root'
    password = '123456'
    LOCAL_MIX_FW_PATH = current_dir+"/Mix_FW/"
    logPath = "/Users/gdlocal/Desktop/"
    mixFileUpdateTargetPath = '/var/fw_update/upload/'

    MixInfo = {
        "stationType":"DFU",
        "SC":{
            "MixName":"MIX_FW_J617_DFU_SC_22.tgz",
            "MixMD5":"d3a0e98a1fa13035b189d3d315788bf5",
            "MixSHA1":"d5bf6b1e4a22278a622913aefd2058c2d18ae3a4",
            "MixVersion":"21.22.16"
        },
        "MT":{
            "MixName":"MIX_FW_J617_DFU_MT_24.tgz",
            "MixMD5":"8a42a0eebb8011cbb521b5d3c90dfe5f",
            "MixSHA1":"502cb4e29b325580cc2354ea0f4ffffe399db5f0",
            "MixVersion":"18.24.16"
        }
    }


    thread_lock = threading.Lock()
    log_file_lock = threading.Lock()
    upgrade_failed_host_ip_address = ''
    log_file = None
    # plist_file = '/Users/gdlocal/Library/Atlas2/Assets/SPI_CHIPS.plist'
    log_file = open(get_fw_abs_path(logPath) + 'MixFWUpgrade_log.txt', mode='w')

    fixtureType,vendorName,currentMixVer = get_xavier_mix_version(baseIPAddress,username,password)
    print('fixtureType,vendorname, currentMixVer: ',fixtureType,vendorName,currentMixVer)
    log_file.write(timeStamp()+'Xavier fixtureType: '+fixtureType+'\n')
    log_file.write(timeStamp()+'Xavier vendorname: '+vendorName+'\n')
    log_file.write(timeStamp()+'Xavier currentMixVer: '+currentMixVer+'\n')

    stationType,localMixName,localMixMD5,localMixSHA1,localMixVersion = getLocalMixInfo(vendorName, MixInfo)
    print('getLocalMixInfo: ',stationType,localMixName,localMixMD5,localMixSHA1,localMixVersion)
    log_file.write(timeStamp()+'stationType: '+ stationType+'\n')
    log_file.write(timeStamp()+'localMixName: '+ localMixName+'\n')
    log_file.write(timeStamp()+'localMixMD5: '+ localMixMD5+'\n')
    log_file.write(timeStamp()+'localMixSHA1: '+ localMixSHA1+'\n')
    log_file.write(timeStamp()+'localMixVersion: '+ localMixVersion+'\n')

    if fixtureType == stationType:
        createDylibShortcut(current_dir,fixtureType,vendorName)
        if checkLocalMixFWFile(LOCAL_MIX_FW_PATH,localMixName,localMixMD5,localMixSHA1) == True:
            ret = mulptiChannelFWUpgrade(LOCAL_MIX_FW_PATH,logPath,localMixName,localMixMD5,localMixSHA1,localMixVersion,mixFileUpdateTargetPath,baseIPAddress,username,password)
            if ret:
                print "upgrade failed! please check,the host ip address as below!\n"
                print ret
                log_file.write(timeStamp()+"upgrade failed! please check,the host ip address as below!\n"+ret)
                exit(1)
            match = is_remote_and_local_fw_version_match(LOCAL_MIX_FW_PATH, baseIPAddress, username, password,localMixVersion)
            if not match:    
                waitForMixFWupdate(LOCAL_MIX_FW_PATH,localMixVersion,baseIPAddress,username,password,currentMixVer)
        else:
            print('Local mix file check failed!')
            log_file.write(timeStamp()+'Local mix file check failed,pls check fixture! :-(\n')

    else:
        print('Unknown fixture Type! :-(')
        log_file.write(timeStamp()+'Unknown fixture Type,pls check fixture! :-(\n')


    log_file.close()