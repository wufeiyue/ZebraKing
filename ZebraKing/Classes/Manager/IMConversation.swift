//
//  IMConversation.swift
//  ZebraKing
//
//  Created by 武飞跃 on 2017/9/11.
//  Copyright © 2017年 ZebraKing. All rights reserved.
//

import Foundation
import ImSDK
import IMMessageExt

public final class IMConversation: NSObject{
  
    //用于chattingConversation收到onNewMessage后的通知,更新IMChatViewController收到的消息,在IMChatViewController消失后,将此回调置为nil,表示不再接收消息
    internal var onReceiveMessageCompletion: MessageCompletion?
    internal var unReadCountCompletion: CountCompletion?
    fileprivate var updateReceiveMessagesCompletion: EmptyCompletion?
    //总的消息数组
    private var pageMessageList = Array<IMMessage>()
    //数据库需要根据此标志位拉取数据
    private var lastMessage:IMMessage?
    //本地存储的未读消息数,由自己管理
    private var localUnReadCount:Int = 0
    //会话对象
    public let conversation:TIMConversation
    
    public init(conversation:TIMConversation) {
        self.conversation = conversation
    }
    
    ///  发送消息
    ///
    /// - Parameters:
    ///   - message: 待发送的消息实例
    ///   - result:
    //FIXME: 将消息数组传出去
    public func send(message:IMMessage, result:@escaping SendResultCompletion) {
        if pageMessageList.isEmpty {
            pageMessageList.append(message)
        }
//        message.updateState(with: .sending)
        conversation.send(message.msg, succ: {
//            message.updateState(with: .sendSucc)
            result(.success)
        }) { (code, description) in
//            message.updateState(with: .sendFail)
            let error = NSError(domain: description ?? "", code: Int(code), userInfo: nil)
            result(.failure(error))
        }
        
    }
    
    /// 切换到本会话前，先加载本地的最后count条聊天的数据
    ///
    /// - Parameters:
    ///   - count: 加载条数
    ///   - completion: 异步回调,返回加载的message数组,数组不为空即为加载成功
    public func loadRecentMessages(count:Int, completion:@escaping LoadResultCompletion) {
        //取到不包含timeTip和saftyTip的message数组
        /*
         消息排序规则:
         前天信息
         昨天信息
         今天信息
         刚刚信息
         */
        let topMessage = pageMessageList.filterFirst(rule: { return $0.isVailedType })
        loadRecentMessages(count: count, from: topMessage, completion: completion)
        
        if topMessage == nil {
            //消息首次加载,让闭包回调出去,表示全部已读
            localUnReadCount = 0
            unReadCountCompletion?(0)
        }
    }
    
    
    /// 删除本次会话聊天记录, 从数据库中清除
    public func deleteLocalMessage(){
        
        //设置最后一条消息为已读状态
        alreadyRead()
        
        conversation.deleteLocalMessage({ [weak self] in
            //移除会话成功, 移除监听
            self?.onReceiveMessageCompletion = nil
            self?.unReadCountCompletion = nil
        }) { [weak self] (code, description) in
            //:TODO 删除失败, 错误处理, 移除监听
            self?.onReceiveMessageCompletion = nil
            self?.unReadCountCompletion = nil
        }
    }
    
    /// 监听收到的消息
    ///
    /// - Parameter msg: 收到的消息
    public func listenerNewMessage(msgList: @escaping MessageListCompletion){
        onReceiveMessageCompletion = { [weak self] in
            guard let this = self else { return }
            let list = this.addMsgToList(msg: $0)
            msgList(list)
        }
    }
    
    /// 监听已读回执的消息状态
    ///
    /// - Parameter result: 消息回调 根据isPeerReaded确认对方是否已读
    public func listenerUpdateReceiptMessages(result: @escaping (()-> Void)) {
        if self.updateReceiveMessagesCompletion == nil {
            //设置消息已读回执的监听
            TIMManager.sharedInstance().getUserConfig().receiptListener = self
        }
        self.updateReceiveMessagesCompletion = result
    }
    
    
    //设置会话消息已读
    public func alreadyRead(message:IMMessage? = nil) {
        alreadyRead(message: message?.msg)
    }
    
    internal func alreadyRead(message:TIMMessage?) {
        conversation.setRead(message, succ: {
            //设置已读成功,不处理回调
        }, fail: { (code , str) in
            //设置消息已读失败, 将造成对方监听消息已读回执的方法不执行
        })
    }
    
    /// 删除本地会话窗口
    public func deleteConversation() {
        TIMManager.sharedInstance()?.deleteConversationAndMessages(.C2C, receiver: conversation.getReceiver())
        unReadCountCompletion = nil
    }
    
    /// 释放当前会话
    public func releaseConversation(){
        pageMessageList.removeAll(keepingCapacity: true)
        onReceiveMessageCompletion = nil
        updateReceiveMessagesCompletion = nil
        TIMManager.sharedInstance().getUserConfig().receiptListener = nil
    }
    
}

extension IMConversation {
    internal func addUnReadCount() {
        if localUnReadCount == 0 {
            localUnReadCount = Int(conversation.getUnReadMessageNum())
        }
        else {
            localUnReadCount += 1
        }
        unReadCountCompletion?(localUnReadCount)
    }
    
    /// 将消息添加到当前会话的消息列表
    ///
    /// - Parameter msg: 当前的消息
    /// - Returns: 新的消息数组
    private func addMsgToList(msg followMessage: IMMessage) -> [IMMessage] {
        
        var array = Array<IMMessage>()
        
        if let timeTip = timeTipOnNewMessageIfNeeded(last: lastMessage, follow: followMessage) {
            array.append(timeTip)
        }
        
        array.append(followMessage)
        
        return array
        
    }
    
    
    /// 对比两个消息,符合规则就添加时间戳
    ///   如果last为空,返回follow的时间戳,如果last不为空且对比follow已超过5分钟,返回follow的时间戳, 否则返回nil
    /// - Parameters:
    ///   - last: 最后一次的消息
    ///   - follow: 后来的消息
    /// - Returns: 时间文本/nil
    public func timeTipOnNewMessageIfNeeded(last:IMMessage?, follow:IMMessage) -> IMMessage?{
        
        if let followDate = follow.msg.timestamp() {
            
            guard let lastDate = last?.msg.timestamp() else {
                return IMMessage(timetip: followDate)
            }
            
            if followDate.timeIntervalSince(lastDate) > TimeInterval(5*60) {
                //大于5分钟
                return IMMessage(timetip: followDate)
            }
            
        }
        
        return nil
    
    }
    
    
    /// 加载最近的消息 以message为Key拿到count条数据
    ///
    /// - Parameters:
    ///   - count: 加载的条数
    ///   - message: 用于检索的message
    ///   - completion: 返回加载的message数组,数组不为空即为加载成功
    private func loadRecentMessages(count: Int, from message: IMMessage?, completion: @escaping LoadResultCompletion){
        
        conversation.getMessage(Int32(count), last: message?.msg, succ: { [weak self](anys) in
            if let messages = anys as? Array<TIMMessage> {
                
                if let tempArray = self?.convertIMMessages(from: messages) {
                    if !tempArray.isEmpty {
                        self?.pageMessageList = tempArray
                    }
                    completion(.success(tempArray))
                }

                if let lastOtherMessage = messages.filterFirst(rule: { $0.isSelf() == false }) {
                    self?.alreadyRead(message: lastOtherMessage)
                }
                
            }
            }, fail: {code , description in
                dispatch_async_safely_to_main_queue {
                    let error = NSError(domain: description ?? "", code: Int(code), userInfo: nil)
                    completion(.failure(error))
                }
                
        })
    }
    
    
    /*  将TIMMessage数组转换成IMMessage数组
     
     元素排列规则为:
     ****** 文本0(数组最后一个元素).timeTip *******
     ****** 文本0 *******
     ****** 文本1.timeTip(如果时间较文本0超5分,才会添加) ******
     ****** 文本1 ******
     ****** 文本2 *******
     */
    private func convertIMMessages(from array:Array<TIMMessage>) -> Array<IMMessage>{
        var tempArray = Array<IMMessage>()
        var prevMessage: TIMMessage?
        for index in (0 ..< array.count).reversed() {
            let message = array[index]
            
            //发送失败的消息也展示出来
//            if message.status() == .MSG_STATUS_SEND_FAIL {
//                continue
//            }
            
            let currentTimestamp = message.timestamp()
            
            if let date = currentTimestamp, index == array.count - 1{
                tempArray.append(IMMessage(timetip: date))
            }
            
            if  let prev = prevMessage,
                let prevDate = prev.timestamp(),
                let unwrappedDate = currentTimestamp {
                
                //大于5分钟
                let timeInterval = unwrappedDate.timeIntervalSince(prevDate)
                if timeInterval > TimeInterval(5 * 60) {
//                    let msg = IMMessage.msgWithDate(timetip: unwrappedDate)
                    let msg = IMMessage(timetip: unwrappedDate)
                    tempArray.append(msg)
                }
            }
            
            prevMessage = message
            
            if let imamsg = IMMessage.msgWith(msg: message){
                tempArray.append(imamsg)
            }
        }
        
        return tempArray
        
    }
}

extension IMConversation {
    /// 加载最新一条消息
    /// 在收到推送消息过来的时候,如果没有lastMessage,就手动检索本地最新消息
    func getLastMessage() -> IMMessage? {
        if self.lastMessage != nil { return self.lastMessage }
        guard let msgs = conversation.getLastMsgs(1) as? [TIMMessage] else { return nil }
        for msg in msgs {
            if let imamsg = IMMessage.msgWith(msg: msg) {
                self.lastMessage = imamsg
                return imamsg
            }
        }
        return nil
    }
    
    //设置最新一条消息
    func set(lastMessage message:IMMessage) {
        self.lastMessage = message
    }
    
    func loadLocalMessages(succ: @escaping TIMGetMsgSucc) {
        conversation.getLocalMessage(1, last: nil, succ: succ, fail: nil)
    }

}

extension Sequence {
    //只取符合要求的第一个元素 应该会比 dataSource.filter({ $0.invailType }).first 性能高
    func filterFirst(rule:(Iterator.Element) -> Bool) -> Iterator.Element? {
        for i in self {
            if rule(i) {
                return i
            }
        }
        return nil
    }
    
}


extension IMConversation: TIMMessageReceiptListener {
    //对方在调用setMessageRead方法时,就会走这个回调(已读回执)
    public func onRecvMessageReceipts(_ receipts: [Any]!) {
        
        guard let list = receipts as? Array<TIMMessageReceipt> else { return }
        
        for receipt in list {
            if receipt.conversation.getReceiver() == self.getReceiver() {
              
                //最后一条消息为已读状态,就直接跳过处理
                let lastMsgs = receipt.conversation.getLastMsgs(1) as! [TIMMessage]
                guard let lastMessage = lastMsgs.first else { return }
                
                if lastMessage.isSelf() && lastMessage.isPeerReaded(){
                    self.alreadyRead(message: lastMessage)
                    self.updateReceiveMessagesCompletion?()
                }
            }
            else {
                self.updateReceiveMessagesCompletion = nil
            }
        }
        
    }
    
}


extension IMConversation {
    
    public func getReceiver() -> String {
        return conversation.getReceiver()
    }
    
}


