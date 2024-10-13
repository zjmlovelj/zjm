import re
import os
import csv
import datetime
import argparse
from log_format_config import *


class LogFile(object):
    def __init__(self, path):
        self.file_path = path
        self.content = []
        self._line_terminator = "\n"
        self._header = None

    @property
    def line_terminator(self):
        return self._line_terminator

    @line_terminator.setter
    def line_terminator(self, terminiator):
        self._line_terminator = terminiator

    @property
    def header(self):
        return self._header

    @header.setter
    def header(self, header):
        self._header = header

    def export(self):
        f = open(self.file_path, "w+")
        for line in self.content:
            f.write(line + self._line_terminator)
        f.close()

    def append(self):
        raise("Not Implemented")


class Pivot(LogFile):
    __record_pattern = "([\w\/:\.\s]+) category.*\[%record%\]\s+\[<([\S\s]+)>\s+<([\S\s]+)>\s+<([\S\s]+)>\]\s+lower:\s+([\S\s]+)\s+higher:\s+([\S\s]+)\s+value:\s+([\S\s]+)\s+unit:\s?([\S\s]+)\s+result:\s+(\w+)\s+failMsg:\s([\S\s]+)"
    TIMESTAMP_FORMAT = EXPORT_TIMESTAMP
    def __init__(self, path, slot):
        super(Pivot, self).__init__(path)
        self.slot = slot

    def append(self, line):
        match = re.findall(Pivot.__record_pattern, line)
        if len(match) > 0:
            timestamp, testname, subtestname, subsubtestname, lower, higher, value, unit, result, message = match[0]
            now_timestamp = datetime.datetime.strptime(timestamp, TIMESTAMP)
            export_timestamp_str = datetime.datetime.strftime(now_timestamp, Pivot.TIMESTAMP_FORMAT)
            # print("Find record: {}, {}, {}, {}, {}, {}, {}, {}".format(timestamp, testname, subtestname, subsubtestname, lower, higher, value, unit, result, message))
            if len(self.content) > 0:
                previous_timestamp = datetime.datetime.strptime(self.content[-1]["timestamp"], Pivot.TIMESTAMP_FORMAT)
                duration_timestamp = now_timestamp - previous_timestamp
                duration = duration_timestamp.days * 24 * 60 * 60 + duration_timestamp.seconds + duration_timestamp.microseconds / 1000000.0
            else:
                duration = "N/A"
            if message.strip() == "nil":
                message = ""
            self.content.append(
                {
                    "lower": lower,
                    "higher": higher,
                    "value": value,
                    "unit": unit,
                    "slot": self.slot,
                    "testname": testname,
                    "subtestname": subtestname,
                    "subsubtestname": subsubtestname,
                    "timestamp": export_timestamp_str,
                    "duration": str(duration),
                    "result": result,
                    "failMsg": message
                }
            )
    
    def export(self):
        print("Logging to {}".format(self.file_path))
        f = open(self.file_path, "w+")
        writer = csv.DictWriter(f, self._header)
        writer.writeheader()
        for line in self.content:
            writer.writerow(line)
        f.close()


class MatchingCollector(object):

    __test_start_pattern = "([\w\/:\.\s]+) category.*\[TEST START\]\s?\[<([\S\s]+)>\s+<([\S\s]+)>\s+<([\S\s]+)>\]"
    __test_pass_pattern = "([\w\/:\.\s]+) category.*\[TEST PASSED\]\s?\[<([\S\s]+)>\s+<([\S\s]+)>\s+<([\S\s]+)>\]"
    __test_fail_pattern = "([\w\/:\.\s]+) category.*\[TEST FAILED\]\s?\[<([\S\s]+)>\s+<([\S\s]+)>\s+<([\S\s]+)>\]"
    __fixture_start_pattern = "([\w\/:\.\s]+) category.*\[%fixture cmd%\]\s+method:\s+([\S\s]+)\s+args:\s+([\S\s]+)\s+timeout:\s+([\S\s]+)"
    __fixture_finish_pattern = "([\w\/:\.\s]+) category.*\[%fixture response%\]\s+([\S\s]+)"
    __fixture_finish_more_pattern = "([\w\/:\.\s]+) category.*\<default>\s?([\S\s]+)"
    __dut_cmd_start_pattern = "([\w\/:\.\s]+) category.*\[%%dut cmd%%\]([\S\s]+)"
    __record_pattern = "([\w\/:\.\s]+) category.*\[%record%\]\s+\[<([\S\s]+)>\s+<([\S\s]+)>\s+<([\S\s]+)>\]\s+lower:\s+([\S\s]+)\s+higher:\s+([\S\s]+)\s+value:\s+([\S\s]+)\s+unit:\s?([\S\s]+)\s+result:\s+(\w+)\s+failMsg:\s([\S\s]+)"
    __dut_cmd_finish_pattern = "([\w\/:\.\s]+) category.*\[%%dut response%%\]([\S\s]+)"
    __dut_cmd_finish_more_pattern = "([\w\/:\.\s]+) category.*\<default>\s?([\S\s]+)"
    __flow_debug_pattern = "([\w\/:\.\s]+) category.*\[%%flow debug%%\]\s+([\S\s]+)"

    _dut_resp_start = False
    _fixture_resp_start = False
    TIMESTAMP_FORMAT = EXPORT_TIMESTAMP

    @classmethod
    def __update_timestamp(cls, timestamp):
        ts = datetime.datetime.strptime(timestamp, TIMESTAMP)
        return datetime.datetime.strftime(ts, MatchingCollector.TIMESTAMP_FORMAT)

    @classmethod
    def collect_test_start(cls, line):
        match = re.findall(MatchingCollector.__test_start_pattern, line)
        if len(match) > 0:
            timestamp, testname, subtestname, subsubtestname = match[0]
            return ("{}{}{:<" + str(TEST_START_INDENTATION) + "}{}{}{}{}{}{}").format(TEST_SEPARATOR, MatchingCollector.__update_timestamp(timestamp), "", TEST_NAME_PREFIX, testname, SUBTEST_NAME_CONNECTOR, subtestname, SUBSUBTEST_NAME_CONNECTOR, subsubtestname)
        else:
            return None

    @classmethod
    def collect_test_pass(cls, line):
        match = re.findall(MatchingCollector.__test_pass_pattern, line)
        if len(match) > 0:
            timestamp, testname, subtestname, subsubtestname = match[0]
            return ("{}{:<" + str(TEST_RESULT_INDENTATION) + "}{}PASS").format(MatchingCollector.__update_timestamp(timestamp), "", TEST_RESULT_PREFIX)
        else:
            return None

    @classmethod
    def collect_test_fail(cls, line):
        match = re.findall(MatchingCollector.__test_fail_pattern, line)
        if len(match) > 0:
            timestamp, testname, subtestname, subsubtestname = match[0]
            return ("{}{:<" + str(TEST_RESULT_INDENTATION) + "}{}FAIL").format(MatchingCollector.__update_timestamp(timestamp), "", TEST_RESULT_PREFIX)
        else:
            return None

    @classmethod
    def collect_record(cls, line):
        match = re.findall(MatchingCollector.__record_pattern, line)
        if len(match) > 0:
            timestamp, testname, subtestname, subsubtestname, lower, higher, value, unit, result, message = match[0]
            return ("{}{:<" + str(RECORD_INDENTATION) + "}{:<" + str(PREFIX_LEN) + "} {:<36} lower: {:<5} higher: {:<5} value: {:<10} unit: {:<5} msg: {}{}").format(MatchingCollector.__update_timestamp(timestamp.strip()), "", RECORD_PREFIX, subsubtestname, lower.strip(), higher.strip(), value.strip(), unit.strip(), message.strip(), RECORD_SUFFIX)
        else:
            return None

    @classmethod
    def collect_fixture_cmd(cls, line):
        match = re.findall(MatchingCollector.__fixture_start_pattern, line)
        if len(match) > 0:
            timestamp, method, args, timeout = match[0]
            return ("{}{:<" + str(FIXTURE_CMD_INDENTATION) + "}{:<" + str(PREFIX_LEN) + "} method: {}, args: {}, timeout: {}{}").format(MatchingCollector.__update_timestamp(timestamp.strip()), "", FIXTURE_CMD_PREFIX, method.strip(), args.strip(), timeout.strip(), FIXTURE_CMD_SUFFIX)
        else:
            return None

    @classmethod
    def collect_fixture_response(cls, line):
        if MatchingCollector._fixture_resp_start:
            if '[INFO]' not in line and '[DEBUG]' not in line:
                match = re.findall(MatchingCollector.__fixture_finish_more_pattern, line)
                if len(match) > 0:
                    timestamp, command = match[0]
                    if len(command.strip()) > 1:
                        return ("{}{:<" + str(FIXTURE_RESP_INDENTATION + PREFIX_LEN) + "} {}").format(timestamp, "", command.strip())
                    else:
                        return None
            else:
                MatchingCollector._fixture_resp_start = False
                return
        match = re.findall(MatchingCollector.__fixture_finish_pattern, line)
        if len(match) > 0:
            timestamp, response = match[0]
            MatchingCollector._fixture_resp_start = True
            return ("{}{:<" + str(FIXTURE_RESP_INDENTATION) + "}{:<" + str(PREFIX_LEN) + "} {}{}").format(MatchingCollector.__update_timestamp(timestamp.strip()), "", FIXTURE_RESP_PREFIX, response.strip(), FIXTURE_RESP_SUFFIX)
        else:
            return None

    @classmethod
    def collect_dut_cmd(cls, line):
        match = re.findall(MatchingCollector.__dut_cmd_start_pattern, line)
        if len(match) > 0:
            timestamp, command = match[0]
            return ("{}{:<" + str(DUT_CMD_INDENTATION) + "}{:<" + str(PREFIX_LEN) + "} {}{}").format(MatchingCollector.__update_timestamp(timestamp.strip()), "", DUT_CMD_PREFIX, command.strip(), DUT_CMD_SUFFIX)
        else:
            return None

    @classmethod
    def collect_dut_response(cls, line):
        if MatchingCollector._dut_resp_start:
            if '[INFO]' not in line and '[DEBUG]' not in line:
                if "channel was stalled due to overlogging" not in line:
                    match = re.findall(MatchingCollector.__dut_cmd_finish_more_pattern, line)
                    if len(match) > 0:
                        timestamp, command = match[0]
                        if len(command.strip()) > 1:
                            return ("{}{:<" + str(DUT_RESP_INDENTATION + PREFIX_LEN) + "} {}").format(MatchingCollector.__update_timestamp(timestamp.strip()), "", command.strip())
                        else:
                            return None
            else:
                MatchingCollector._dut_resp_start = False
                return
        match = re.findall(MatchingCollector.__dut_cmd_finish_pattern, line)
        if len(match) > 0:
            timestamp, response = match[0]
            MatchingCollector._dut_resp_start = True
            return ("{}{:<" + str(DUT_RESP_INDENTATION) + "}{:<" + str(PREFIX_LEN) + "} {}{}").format(MatchingCollector.__update_timestamp(timestamp.strip()), "", DUT_RESP_PREFIX, response.strip(), DUT_RESP_SUFFIX)
        else:
            return None

    @classmethod
    def collect_flow_debug(cls, line):
        match = re.findall(MatchingCollector.__flow_debug_pattern, line)
        if len(match) > 0:
            timestamp, response = match[0]
            return ("{}{:<" + str(FLOW_DEBUG_INDENTATION) + "}{:<" + str(PREFIX_LEN) + "} {}{}").format(MatchingCollector.__update_timestamp(timestamp.strip()), "", FLOW_DEBUG_PREFIX, response.strip(), FLOW_DEBUG_SUFFIX)
        else:
            return None

class FlowLog(LogFile):

    __matching_pattern = {
        "[TEST START]": MatchingCollector.collect_test_start,
        "[TEST PASSED]": MatchingCollector.collect_test_pass,
        "[TEST FAILED]": MatchingCollector.collect_test_fail,
        "[%fixture cmd%]": MatchingCollector.collect_fixture_cmd,
        "[%fixture response%]": MatchingCollector.collect_fixture_response,
        "[%record%]": MatchingCollector.collect_record,
        "[%%dut cmd%%]": MatchingCollector.collect_dut_cmd,
        "[%%dut response%%]": MatchingCollector.collect_dut_response,
        "[%%flow debug%%]": MatchingCollector.collect_flow_debug
    }


    def __init__(self, path):
        super(FlowLog, self).__init__(path)

    def append(self, line):
        for keyword, collector in FlowLog.__matching_pattern.items():
            if keyword in line or (MatchingCollector._dut_resp_start == True and keyword == "[%%dut response%%]") or (MatchingCollector._fixture_resp_start == True and keyword == "[%fixture response%]"):
                collected = collector(line)
                if collected:
                    self.content.append(collected)

    def export(self):
        print("Logging to {}".format(self.file_path))
        f = open(self.file_path, "w+")
        for line in self.content:
            f.write(line + "\n")
        f.close()

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-l', '--log', help="device log path", type=str)
    parser.add_argument('-o', '--output', help="output path", type=str)
    parser.add_argument('-s', '--slot', help="slot name", type=str, default="slot1")

    args = parser.parse_args()
    pivot = Pivot(os.path.join(args.output, "pivot.csv"), args.slot)
    pivot._header = ["slot", "testname", "subtestname", "subsubtestname", "unit", "lower", "higher", "timestamp", "duration", "result", "value", "failMsg"]
    flow = FlowLog(os.path.join(args.output, "flow.log"))
    with open(args.log, 'r') as f:
        for line in f.readlines():
            flow.append(line)
            if "[%record%]" in line:
                pivot.append(line)                

    pivot.export()
    flow.export()


