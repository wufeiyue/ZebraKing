//
//  Conversation.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/7/18.
//

import Foundation
import IMMessageExt
import ImSDK

open class Conversation: NSObject {
    
    /// 主机
    internal var host: Sender!
    
    /// 会话
    internal let conversation: IMConversation
    
    /// 聊天对象
    internal var receiver: Sender!
    
    public init(host: Sender, receiver: Sender, task: IMConversation) {
        self.host = host
        self.receiver = receiver
        self.conversation = task
        super.init()
    }
    
    ///  发送消息
    ///
    /// - Parameters:
    ///   - message: 待发送的消息实例
    ///   - result:
    //FIXME: 将消息数组传出去
    open func send(message: IMMessage, result:@escaping SendResultCompletion) {
        DispatchQueue.main.async {
            self.conversation.send(message: message, result: result)
        }
    }
    
    /// 移除自身
    open func releaseSelf() {
        IMChatManager.default.releaseConversation()
    }
    
    /// 监听收到的消息
    ///
    /// - Parameter msg: 收到的消息
    open func listenerNewMessage(msgList: @escaping MessageListCompletion) {
        DispatchQueue.main.async {
            
            self.conversation.listenerNewMessage(msgList: { (messages) in
                    
                self.queryFriendProfile(result: {
                    msgList(self.updateMessages(messages, receiver: $0.value))
                })
                
            })
            
        }
    }
    
    /// 监听已读回执的消息状态
    ///
    /// - Parameter result: 消息回调 根据isPeerReaded确认对方是否已读
    open func listenerUpdateReceiptMessages(result: @escaping (()-> Void)) {
        conversation.listenerUpdateReceiptMessages(result: result)
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
                
                self.queryFriendProfile(result: {
                    completion(.success(self.updateMessages(messages, receiver: $0.value)))
                })
                
            case .failure(let error):
                completion(.failure(error))
            }
        }
    }
    
    private func updateMessages(_ originList: Array<IMMessage>, receiver: Sender?) -> Array<IMMessage> {
        return originList.map({ (message) in
            if message.isMineMsg {
                message.receiver = host
            }
            else {
                message.receiver = receiver
            }
            return message
        })
    }
    
    private func queryFriendProfile(result: @escaping (IMResult<Sender>) -> Void) {
        IMChatManager.default.userManager.queryFriendProfile(id: receiver.id, placeholder: receiver.placeholder, result: result)
    }
}
