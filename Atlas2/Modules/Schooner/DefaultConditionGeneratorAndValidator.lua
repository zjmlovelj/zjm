m = {}

function m.product()
    local p = Atlas.loadPlugin('StationInfo')
    return p.product()
end

function m.stationType()
    local p = Atlas.loadPlugin('StationInfo')
    return p.station_type()
end

function m.returnTrue()
    print('Debug: return True for condition validator')
    return true
end

return m
