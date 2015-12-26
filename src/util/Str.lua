module("Str", package.seeall)

local t_str = require('src/config/t_str')

function init()
    for k,v in pairs(t_str) do
        Str[k] = v["value"]
    end
end