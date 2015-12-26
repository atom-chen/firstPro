module("Mail", package.seeall)

local _mailList = {}      --邮件列表
local _mailListItem = {
    id = 0,               --邮件ID
    read = 0,             --0:未读
    title = "",           --邮件名
    content = "",         --邮件内容
    sign = "",            --邮件发生者
    items = {},           --邮件奖品 [{"itemID":3401,"num":100},{"itemID":3006,"num":2}]
    time                  --邮件时间
}

--获取邮件列表
function getMailList()
    return _mailList
end

--根据邮件ID获取邮件列表
function getMailByMailID(id)
    return _mailList[id]
end

--根据邮件ID删除邮件
function delMailByMailID(id)
    _mailList[id] = nil
end

--解析邮件
function parseMail(msg)
    local mailList = msg["mails"]
    if mailList then
        for i=1, #mailList do
            local mailTemp = mailList[i]
            local mailListItem = clone(_mailListItem)
            mailListItem.id = mailTemp["id"]
            mailListItem.title = mailTemp["title"]
            mailListItem.content = mailTemp["content"]
            mailListItem.sign = mailTemp["sign"]
            mailListItem.items = mailTemp["items"]
            mailListItem.time = mailTemp["time"]
            mailListItem.read = mailTemp["read"]
            _mailList[mailListItem.id] = mailListItem
        end
    end
end

--新邮件推送
function parseNewMail(msg)
    local mailListItem = clone(_mailListItem)
    mailListItem.id = msg["id"]
    mailListItem.title = msg["title"]
    mailListItem.content = msg["content"]
    mailListItem.sign = msg["sign"]
    mailListItem.items = msg["items"]
    mailListItem.time = msg["time"]
    mailListItem.read = msg["read"]
    _mailList[mailListItem.id] = mailListItem
    
    Event.notify(Const.EVENT.MAIL, mailListItem)
end

--设置邮件为已读取
function setMailRead(id)
    local mail = _mailList[id]
    if mail then
    	mail["read"] = 1
    end
end