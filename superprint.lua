----------------------------
    -- Superprint
----------------------------
local superprint = {
    -- Table of functions to be called with print commands
    print_functions = {
        ["wobble"] = function(str, x, y, h, v)
            local t = os.clock() 
            return str, x+(math.cos(t)*h), y+(math.sin(t)*v)
        end,
        
        ["normal"] = function(str, x, y)
            return str, x, y
        end,
        
        ["color"] = function(str, x, y, r, g, b, a)
            if tonumber(r) == nil then
                love.graphics.setColor(unpack(superprint.print_color[r]))
            else
                love.graphics.setColor(r, g, b, a)
            end
            return str, x, y
        end,
        
        ["font"] = function(str, x, y, name)
            love.graphics.setFont(superprint.print_font[name])
            return str, x, y
        end
    },

    -- Table of colors to be called with print commands
    print_color = {
        ["red"]     = {0xFF, 0x00, 0x00},
        ["green"]   = {0x00, 0xFF, 0x00},
        ["blue"]    = {0x00, 0x00, 0xFF},
        ["white"]   = {0xFF, 0xFF, 0xFF},
        ["black"]   = {0x00, 0x00, 0x00},
    },

    -- Table of fonts to be called with print commands
    print_font = {
        ["default"] = love.graphics.getFont()
    },
}

-- Token data
local token = {
    ["OpenArguments"]   = "(",
    ["CloseArguments"]  = ")",
    ["StackAndOp"]      = "&",
    ["NewArgument"]     = ",",
    ["SubString"]       = "'",
}

-- Add elements to superprint tables
function superprint.addfunction(name, func)
    superprint.print_functions[name] = func
end

function superprint.addfont(name, font)
    superprint.print_font[name] = font
end

-- Process a string
function superprint.process(str)
    -- Superprint data table
    local print_data = {}
    
    -- Booleans
    local parse_arg, in_string = false, false

    -- Temporary storage
    local sub_string, arg_string, func_name = "", "", ""
    local arg_table = {}

    -- Where we store our final data
    local main_table = {}

    -- Assign initial font as the printing font
    local print_font = love.graphics.getFont()

    -- Offsets for substrings
    local x, y = 0, 0

    for char in str:gmatch"." do
        -- Ignore blank spaces unless we're in the string
        if char ~= " " or in_string then
            -- Argument begin -------------------------------------------------------
            if char == token["OpenArguments"] and not in_string then
                parse_arg = true
            
            -- Argument end ---------------------------------------------------------
            elseif char == token["CloseArguments"] and not in_string then
                -- Finalize argument collection
                if arg_string ~= "" then
                    table.insert(arg_table, arg_string)
                    arg_string = ""
                    
                    -- Stop parsing for arguments
                    parse_arg = false
                end
                
                -- Export collected data
                table.insert(main_table, {func_name, arg_table})
                
                -- Reset variables
                func_name = ""
                arg_table = {}
            
            -- Stacking operator ----------------------------------------------------
            elseif char == token["StackAndOp"] and not in_string then
                -- Reset variables
                func_name = ""
                arg_table = {}
                
            -- Comma ----------------------------------------------------------------
            elseif char == token["NewArgument"] and not in_string then
                -- Add argument, reset for next one
                table.insert(arg_table, arg_string)
                arg_string = ""
            
            -- Substring begin ------------------------------------------------------
            elseif char == token["SubString"] and not in_string then
                in_string = true
            
            -- Substring end --------------------------------------------------------
            elseif char == token["SubString"] and in_string then
                -- Push our data into the returned table
                table.insert(main_table, {sub_string, x, y})
                table.insert(print_data, main_table)
                
                -- Reset the substring
                sub_string = ""
                
                -- Offsets for the next sub_string
                x = x + print_font:getWidth(sub_string)
                
                -- Reset the main table for the next function
                main_table = {}
                
                -- Stop parsing for the substring
                in_string = false
                
            -- Character isn't a token, parse text, function name or arguments
            elseif parse_arg then
                arg_string = arg_string .. char
            elseif in_string then
                sub_string = sub_string .. char
            else
                func_name = func_name .. char
            end
        end
    end
    
    return print_data
end

-- Print saved superprint data
function superprint.print(print_data)
    -- Previous global color and font
    local r, g, b, a = love.graphics.getColor()
    local font = love.graphics.getFont()

    for i, v in ipairs(print_data) do
        -- Unpack main data
        local table, main_args = unpack(v)
        local str, x, y = unpack(v[#v])

        -- Unpack superprint data
        for j = 1, #v - 1 do
            local name, args = unpack(v[j])
            str, x, y = superprint.print_functions[name](str, x, y, unpack(args))
        end
        
        love.graphics.print(str, x, y)
    end
    
    -- Reset
    love.graphics.setFont(font)
    love.graphics.setColor(r, g, b, a)
end

return superprint
