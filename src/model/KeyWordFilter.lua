module("KeyWordFilter", package.seeall)

local crab = require "crabWords"
local utf8 = require "utf8Words"

local _keyWordList = require("src/config/t_key_word") --关键字

--关键字字典
local words = {}

--关键字字典
local function makeKeyWordDictionary()
    for k,v in pairs(_keyWordList) do
        local str = tostring(v.keyword)
        if string.len(str) > 0 then --忽略空字符串
            local t = {}
            assert(utf8.toutf32(str, t), "non utf8 words detected:"..str)
            table.insert(words, t)
        end
    end

    crab.open(words)
end

--句子中的脏字部分被替换成*
--return: 过滤后的句子
function filterKeyWord(words)
    local texts = {}
    assert(utf8.toutf32(words, texts), "non utf8 words detected:", texts)
    crab.filter(texts)
    local output = utf8.toutf8(texts)

    return output
end

function toutf32(words)
    local texts = {}
    assert(utf8.toutf32(words, texts), "non utf8 words detected:", texts)

    return texts
end

function toutf8(words)
    return utf8.toutf8(words)
end

--建立关键字字典
makeKeyWordDictionary()