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
    
    /// 会话
    private let conversation: Conversation
    
    private var updateReceiveMessagesCompletion: (() -> Void)?
    //FIXME: 有的会话不需要监听已读未读消息, 后期考虑做成插件, 可选的功能
    private var isNeedListenterUpdateReceiveMessage: Bool = true
    
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
                    self.receiver = $0.value
                    completion(self.updateMessages(list))
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
    ///   - count: 加载条数
    ///   - completion: 异步回调,返回加载的message数组,数组不为空即为加载成功
    open func loadRecentMessages(count:Int, completion:@escaping LoadResultCompletion) {
        conversation.loadRecentMessages(count: count) { (result) in
            switch result {
            case .success(let messages):

                //依据本地是否有消息记录, 如果有记录再获取好友资料
                guard messages.isEmpty == false else {
                    completion(.success(messages))
                    return
                }

                self.queryFriendProfile(id: self.receiver.id, result: {
                    self.receiver = $0.value
                    completion(.success(self.updateMessages(messages)))
                })
                
                if self.isNeedListenterUpdateReceiveMessage {
                    self.isNeedListenterUpdateReceiveMessage = false
                    TIMManager.sharedInstance().getUserConfig().receiptListener = self
                }

            case .failure(let error):
                completion(.failure(error))
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
    
    private func queryFriendProfile(id: String, result: @escaping (IMResult<Sender>) -> Void) {
        SessionManager.default.queryFriendProfile(id: id, result: result)
    }
    
}

extension Task: TIMMessageReceiptListener {
    
    //对方在调用setMessageRead方法时,就会走这个回调(已读回执)
    public func onRecvMessageReceipts(_ receipts: [Any]!) {
        
        guard let list = receipts as? Array<TIMMessageReceipt> else { return }
        
        for receipt in list {
            
            //是否为同一个会话
            guard receipt.conversation.getReceiver() == conversation.conversation.getReceiver() else {
                return
            }
            
            //最后一条消息为已读状态,就直接跳过处理
            let lastMsgs = conversation.conversation.getLastMsgs(1) as! [TIMMessage]
            guard let lastMessage = lastMsgs.first else { return }
            
            if lastMessage.isSelf() && lastMessage.isPeerReaded(){
                DispatchQueue.main.async {
                    self.conversation.alreadyRead(message: lastMessage)
                    self.updateReceiveMessagesCompletion?()
                }
            }
            
        }
        
    }
    
}
