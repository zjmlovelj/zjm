local DiagsTriage = {}

function DiagsTriage.captureTriage(dut, testName)
  local commandToSend = "triage"
  if testName ~= nil then
    commandToSend = commandToSend .. " -t " .. testName
  end

  local response = dut.send(commandToSend)
  local triagePath = string.match(response, "Triage will be stored at ([%w%p]+)")

  return triagePath
end

function DiagsTriage.transferTriageToHost(efiPlugin, usbfsPlugin, hostDir, dutPath)
  usbfsPlugin.copyToHost(efiPlugin, hostDir, {[dutPath] = "" })
  local filename  = dutPath:match("^.+\\(.+)$")

  local hostPath = hostDir .. filename
  return hostPath
end

function DiagsTriage.captureAndTransferToHost(efiPlugin, usbfsPlugin, hostDir, testName)
  local path = DiagsTriage.captureTriage(efiPlugin, testName)
  local hostPath = DiagsTriage.transferTriageToHost(efiPlugin, usbfsPlugin, hostDir, path)

  return hostPath
end

return DiagsTriage
