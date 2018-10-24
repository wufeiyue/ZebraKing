//
//  ZebraKing.swift
//  ZebraKing
//
//  Created by 武飞跃 on 2017/9/11.
//  Copyright © 2017年 武飞跃. All rights reserved.
//

import Foundation
import IMMessageExt
import ImSDK

open class Task: NSObject {
    
    /// 主机
    public var host: Sender!
    
    /// 聊天对象
    public var receiver: Sender!
    
    //消息列表
    public private(set) var messagesList = MessagesList<MessageElem>()
    
    /// 会话
    private let conversation: Conversation
    
    private var updateReceiveMessagesCompletion: (() -> Void)?
    //FIXME: 有的会话不需要监听已读未读消息, 后期考虑做成插件, 可选的功能
    private var isNeedListenterUpdateReceiveMessage: Bool = true
    
    //加载消息条数
    public var loadMessageCount: Int = 20
    
    public init(host: Sender, receiver: Sender, conversation: Conversation) {
        self.host = host
        self.receiver = receiver
        self.conversation = conversation
        super.init()
    }
    
    ///  发送消息
    ///
    /// - Parameters:
    ///   - message: 待发送的消息实例
    ///   - result:
    //FIXME: 将消息数组传出去
    open func send(message: MessageElem, result:@escaping SendResultCompletion) {
        DispatchQueue.main.async {
            self.conversation.send(message: message, result: result)
        }
    }
    
    /// 移除自身
    open func free() {
        SessionManager.default.waiveChat()
        TIMManager.sharedInstance().getUserConfig().receiptListener = nil
    }
    
    
    
    /// 监听收到的消息
    ///
    /// - Parameter msg: 收到的消息
    open func listenerNewMessage(completion: @escaping MessageListCompletion) {
        DispatchQueue.main.async {
            
            self.conversation.listenerNewMessage(completion: { (list) in
                
                self.queryFriendProfile(id: self.receiver.id, result: {
                    
                    let receiverMsgList = self.updateMessages(list)
                    
                    self.receiver = $0.value
                    self.messagesList.addList(newsList: receiverMsgList)
                    
                    completion(receiverMsgList)
                })
                
                if self.isNeedListenterUpdateReceiveMessage {
                    self.isNeedListenterUpdateReceiveMessage = false
                    TIMManager.sharedInstance().getUserConfig().receiptListener = self
                }
                
            })
        }
    }
    
    /// 监听已读回执的消息状态
    ///
    /// - Parameter result: 消息回调 根据isPeerReaded确认对方是否已读
    open func listenerUpdateReceiptMessages(result: @escaping (()-> Void)) {
        updateReceiveMessagesCompletion = result
    }
    
    /// 切换到本会话前，先加载本地的最后count条聊天的数据
    ///
    /// - Parameters:
    ///   - completion: 异步回调,返回加载的message数组,有可能回调成功时, 返回的数据为空
    open func loadRecentMessages(completion:@escaping (Result<Array<MessageElem>>, Bool) -> Void) {
        conversation.loadRecentMessages(count: loadMessageCount) { (result) in
            
            let isFirstLoadData = self.messagesList.isEmpty
            
            switch result {
            case .success(let messages):

                //依据本地是否有消息记录, 如果有记录再获取好友资料
                guard messages.isEmpty == false else {
                    completion(.success(messages), isFirstLoadData)
                    return
                }
                
                self.messagesList.inset(newsList: messages)

                self.queryFriendProfile(id: self.receiver.id, result: {
                    self.receiver = $0.value
                    completion(.success(self.updateMessages(messages)), isFirstLoadData)
                })
                
                if self.isNeedListenterUpdateReceiveMessage {
                    self.isNeedListenterUpdateReceiveMessage = false
                    TIMManager.sharedInstance().getUserConfig().receiptListener = self
                }

            case .failure(let error):
                completion(.failure(error), isFirstLoadData)
            }
        }
    }
    
    /// 删除本地会话窗口
    public func deleteConversation() {
        TIMManager.sharedInstance()?.deleteConversationAndMessages(.C2C, receiver: receiver.id)
    }
    
    private func updateMessages(_ originList: Array<MessageElem>) -> Array<MessageElem> {
        return originList.map({
            //FIXME: 代码不优雅
            if $0.message == nil || $0.message.isSelf() {
                $0.messageSender = host
            }
            else {
                $0.messageSender = receiver
            }
            return $0
        })
    }
    
    private func queryFriendProfile(id: String, result: @escaping (Result<Sender>) -> Void) {
        SessionManager.default.queryFriendProfile(id: id, result: result)
    }
    
    //当页面被电话, 锁屏打断时, 就不将接收到的消息自动设置为已读状态, 和active搭配使用
    public func resign() {
        SessionManager.default.isAutoDidReadedWhenReceivedMessage = false
    }
    
    //当重新回到页面时, 将全部消息设置为已读, 和resign搭配使用
    public func active() {
        SessionManager.default.isAutoDidReadedWhenReceivedMessage = true
        conversation.alreadyRead()
    }
    
    
}

extension Task {
    open func removeLast() {
        messagesList.removeLast()
    }
    
    open func replaceLast() {
        messagesList.removeLast()
    }
    
    func replaceLast(_ newElement: MessageElem) {
        messagesList.replaceLast(newElement)
    }
    
    func append(_ newElement: MessageElem) {
        messagesList.append(newElement)
    }
    
    //当内存吃紧时, 自动移除数组元素
    open func removeSubrange() {
        messagesList.removeSubrange(num: 20)
    }
}


extension Task: TIMMessageReceiptListener {
    
    //对方在调用setMessageRead方法时,就会走这个回调(已读回执)
    public func onRecvMessageReceipts(_ receipts: [Any]!) {
        
        guard let list = receipts as? Array<TIMMessageReceipt> else { return }
        
        for receipt in list {
            
            //是否为同一个会话
            guard receipt.conversation.getReceiver() == conversation.receiverId else {
                return
            }
            
            //从本地缓存中, 取最新一条消息
            if let lastMessage = conversation.conversation.getLastMsgs(1).first as? TIMMessage {

                //消息是我发出去的, 并且对方已读
                if lastMessage.isSelf() && lastMessage.isPeerReaded() {
                    //设置为已读
                    conversation.alreadyRead()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        self.updateReceiveMessagesCompletion?()
                    }
                    return
                }

            }
            
        }
        
    }
    
}
