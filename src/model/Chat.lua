module("Chat", package.seeall)

require("mime")

local _chatGlobalList = {}      --全服聊天列表
local _chatUnionList = {}      --公会聊天列表

--聊天内容
local _chatListItem = {
    id = 0,               --聊天者ID
    time,                 --聊天时间
    msg = "",             --聊天内容
    lv = 0,               --聊天者等级
    nick = "",            --聊天者名字
    fashionID = 0,        --聊天者头像ID
}

--添加聊天消息
local function addWorldChat(chatT)
    local chatGlobalListItem = clone(_chatListItem)
    chatGlobalListItem.id = chatT["id"]
    chatGlobalListItem.time = chatT["time"]
    chatGlobalListItem.msg = chatT["msg"]
    chatGlobalListItem.lv = chatT["lv"]
    chatGlobalListItem.nick = mime.unb64(chatT["nick"])
    chatGlobalListItem.fashionID = chatT["fashionID"]
    table.insert(_chatGlobalList, chatGlobalListItem)
end

--从开头删除一条全服聊天消息
function delGlobalChat()
    table.remove(_chatGlobalList, 1)
end

--从开头删除一条公会聊天消息
function delUnionChat()
    table.remove(_chatUnionList, 1)
end

--获得全服聊天列表
function getGlobalChatList()
    return _chatGlobalList
end

--获得公会聊天列表
function getUnionChatList()
    return _chatUnionList
end

--解析消息
function parseChat(msg)
    local chatGlobal = msg["global"] --全服聊天
    if chatGlobal then
        for i=1, #chatGlobal do
            local globalTemp = chatGlobal[i]
            addWorldChat(globalTemp)
        end
    end
    
    local chatUnion = msg["union"] --公会聊天
    if chatUnion then
        for i=1, #chatUnion do
            local unionTemp = chatUnion[i]
            local chatListItem = clone(_chatListItem)
            chatListItem.id = unionTemp["id"]
            chatListItem.time = unionTemp["time"]
            chatListItem.msg = unionTemp["msg"]
            chatListItem.lv = unionTemp["lv"]
            chatListItem.nick = mime.unb64(unionTemp["nick"])
            chatListItem.fashionID = unionTemp["fashionID"]
            table.insert(_chatUnionList, chatListItem)
            
            --eventUtil.dispatchCustom("ui_ChatWidget_new_chat_receive", {world = false, param = unionTemp})
        end
    end
end

--接收新的世界聊天消息
function parseWorldChat(msg)
    if msg.nick then
        msg.nick=mime.unb64(msg.nick)
    end
    addWorldChat(msg)
    
    eventUtil.dispatchCustom("ui_ChatWidget_new_chat_receive", {world = true, param = msg})
end