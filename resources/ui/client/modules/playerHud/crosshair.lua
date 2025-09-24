xhair = {
    enabled = true,
    colour = "#fff" -- Default color (white)
}

-- Define a mapping of color names to hex values
local colorMap = {
    red = "#ff0000",
    blue = "#0000ff",
    green = "#00ff00",
    cyan = "#00ffff",
    yellow = "#ffff00",
    purple = "#800080", -- Example, adjust as needed
    white = "#ffffff",
    black = "#000000",
    -- Add more colors as needed
}

local send_nui_message = SendNUIMessage

-- Command to set crosshair color
RegisterCommand('crosshair_color', function(src, args, rawCommand)
    local colorArg = string.lower(args[1] or "")

    if colorMap[colorArg] then
        xhair.colour = colorMap[colorArg]
        SetResourceKvp('xhairSettings', json.encode(xhair))
        send_nui_message({ type = "xhair_colour", color = xhair.colour })
    else
        -- Invalid color name or no color provided
        print("Invalid color name or no color provided.")
    end
end)

-- Command to toggle crosshair visibility
RegisterCommand('crosshair_toggle', function(src, args, rawCommand)
    xhair.enabled = not xhair.enabled
    SetResourceKvp('xhairSettings', json.encode(xhair))
    send_nui_message({ type = "xhair", cross = xhair.enabled })
end)
