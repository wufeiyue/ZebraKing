//
//  Conversation.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/7/18.
//

import Foundation
import IMMessageExt
import ImSDK

protocol ConversationDelegate: class {
    
    /// 将消息添加到当前会话的消息列表
    ///
    /// - Parameter msg: 当前的消息
    /// - Returns: 新的消息数组
    func addMsgToList(msg followMessage: MessageElem, lastMessage: TIMMessage?) -> Array<MessageElem>
    
    /// 对比两个消息,符合规则就添加时间戳
    ///   如果last为空,返回follow的时间戳,如果last不为空且对比follow已超过5分钟,返回follow的时间戳, 否则返回nil
    /// - Parameters:
    ///   - last: 最后一次的消息
    ///   - follow: 后来的消息
    /// - Returns: 时间文本/nil
    func timeTipOnNewMessageIfNeeded(last: Date?, follow: Date?) -> Date?
    
    /*  将TIMMessage数组转换成IMMessage数组
     
     元素排列规则为:
     ****** 文本0(数组最后一个元素).timeTip *******
     ****** 文本0 *******
     ****** 文本1.timeTip(如果时间较文本0超5分,才会添加) ******
     ****** 文本1 ******
     ****** 文本2 *******
     */
    func convertMessageElem(from array: Array<TIMMessage>) -> Array<MessageElem>
}

extension ConversationDelegate {
    
    public func timeTipOnNewMessageIfNeeded(last: Date?, follow: Date?) -> Date? {
        
        guard let followDate = follow else { return nil }
        
        if let lastDate = last {
            if followDate.timeIntervalSince(lastDate) > TimeInterval(5*60)  {
                //大于5分钟
                return followDate
            }
            else {
                return nil
            }
        }
        else {
            return followDate
        }
        
    }
    
    
    func convertMessageElem(from array: Array<TIMMessage>) -> Array<MessageElem> {
        
        var tempArray = Array<MessageElem>()
        var prevMessage: TIMMessage?
        
        for index in (0 ..< array.count).reversed() {
            
            let message = array[index]
            let currentTimestamp = message.timestamp()
            
            if let date = currentTimestamp, index == array.count - 1 {
                tempArray.append(MessageElem(dateMessage: date))
            }
            
            if  let prev = prevMessage,
                let prevDate = prev.timestamp(),
                let unwrappedDate = currentTimestamp {
                
                //大于5分钟
                let timeInterval = unwrappedDate.timeIntervalSince(prevDate)
                if timeInterval > TimeInterval(5 * 60) {
                    let msg = MessageElem(dateMessage: unwrappedDate)
                    tempArray.append(msg)
                }
            }
            
            prevMessage = message
            
            let imamsg = MessageElem(message: message)
            tempArray.append(imamsg)
        }
        
        return tempArray
        
    }
    
    
    func addMsgToList(msg followMessage: MessageElem, lastMessage: TIMMessage?) -> Array<MessageElem> {
        
        var array = Array<MessageElem>()
        
        if let timeTip = timeTipOnNewMessageIfNeeded(last: lastMessage?.timestamp(), follow: followMessage.timestamp) {
            let dateMessage = MessageElem(dateMessage: timeTip)
            array.append(dateMessage)
        }
        
        array.append(followMessage)
        
        return array
        
    }
}


open class Conversation {
    
    var conversation: TIMConversation
    
    public var onReceiveMessageCompletion: ((_ message: TIMMessage) -> Void)?
    
    public var updateReceiveMessagesCompletion: (() -> Void)?
    
    //数据库需要根据此标志位拉取数据
    private var lastMessage: MessageElem?
    
    //总的消息数组
    private var pageMessageList = Array<MessageElem>()
    
    public init?(type: TIMConversationType, id: String) {
        
        guard let conversation = TIMManager.sharedInstance().getConversation(type, receiver: id ) else {
            return nil
        }
        
        self.conversation = conversation
    }
    
    public init(conversation: TIMConversation) {
        self.conversation = conversation
    }
    
    ///  发送消息
    ///
    /// - Parameters:
    ///   - message: 待发送的消息实例
    ///   - result:
    //FIXME: 将消息数组传出去
    public func send(message: MessageElem, result:@escaping SendResultCompletion) {
        
        conversation.send(message.message, succ: { [weak self] in
            
            result(.success(true))
            
            guard let this = self else { return }
            
            if this.pageMessageList.isEmpty {
                this.pageMessageList.append(message)
            }
            
            this.lastMessage = message
            
        }) { (code, description) in
            if code == 80001 {
                result(.failure(.unsafe))
            }
            else {
                result(.failure(.sendMessageFailure))
            }
        }
        
    }
    
    
    /// 监听收到的消息
    ///
    /// - Parameter msg: 收到的消息
    public func listenerNewMessage(completion: @escaping MessageListCompletion){
        onReceiveMessageCompletion = { [weak self] in
            guard let this = self else { return }
            //监听到的新消息
            let message = MessageElem(message: $0)
            //组成新的消息集合, 一块发出去
            let messageMap = this.addMsgToList(msg: message, lastMessage: this.lastMessage?.message)
            //将监听到的消息作为最新一条消息
            this.lastMessage = message
            completion(messageMap)
        }
    }
    
    /// 设置消息已读
    ///
    /// - Parameter message: SDK中的消息类型
    public func alreadyRead(message: TIMMessage? = nil) {
        
        //必须是接收到的消息, 才可主动设置为已读
        guard message?.isSelf() == false || message == nil else {
            //TODO: 筛选出最后一条对方的消息, 并设置为已读(数组排序要优化一下, 因为数据比较多)
            return
        }
        
        conversation.setRead(message, succ: {
            //设置已读成功,不处理回调
        }) { (code, string) in
            //FIXME: - 设置消息已读失败, 将造成对方监听消息已读回执的方法不执行
        }
    }
    
    /// 删除本地会话窗口
    public func delete(with type: TIMConversationType) {
        TIMManager.sharedInstance()?.deleteConversationAndMessages(type, receiver: receiverId)
    }
    
    //释放自己
    open func free() {
        pageMessageList.removeAll(keepingCapacity: false)
        onReceiveMessageCompletion = nil
        updateReceiveMessagesCompletion = nil
    }
    
    deinit {
        onReceiveMessageCompletion = nil
        updateReceiveMessagesCompletion = nil
    }
    
  
}

extension Conversation: ConversationDelegate {
    
    /// 切换到本会话前，先加载本地的最后count条聊天的数据
    ///
    /// - Parameters:
    ///   - count: 加载条数
    ///   - completion: 异步回调,返回加载的message数组,数组不为空即为加载成功
    public func loadRecentMessages(count:Int, completion:@escaping (Result<Array<MessageElem>>) -> Void) {
        //取到不包含timeTip和saftyTip的message数组
        /*
         消息排序规则:
         前天信息
         昨天信息
         今天信息
         刚刚信息
         */
        let topMessage = pageMessageList.first(where: { $0.isVailedType })
        loadRecentMessages(count: count, from: topMessage, completion: completion)
    }
    
    
    /// 加载最近的消息 以message为Key拿到count条数据
    ///
    /// - Parameters:
    ///   - count: 加载的条数
    ///   - message: 用于检索的message
    ///   - completion: 返回加载的message数组,数组不为空即为加载成功
    private func loadRecentMessages(count: Int, from message: MessageElem?, completion: @escaping (Result<Array<MessageElem>>) -> Void){
        
        conversation.getMessage(Int32(count), last: message?.message, succ: { [weak self](anys) in
            
            guard let messages = anys as? Array<TIMMessage> else { return }
                
            if let tempArray = self?.convertMessageElem(from: messages) {
                if !tempArray.isEmpty {
                    self?.pageMessageList = tempArray
                }
                completion(.success(tempArray))
            }
            
            //将本地加载的这页数据时间最近的一条筛选出来, 然后设置为已读
            if let lastOtherMessage = messages.first(where: { $0.isSelf() == false }), lastOtherMessage.isPeerReaded() == false {
                self?.alreadyRead(message: lastOtherMessage)
            }
            
            }, fail: {code , description in
                DispatchQueue.main.async {
                    completion(.failure(.loadLocalMessageFailure))
                }
        })
    }
    
}

extension Conversation: Hashable {

    public var hashValue: Int {
        return conversation.hashValue
    }
    
    public static func == (lhs: Conversation, rhs: Conversation) -> Bool {
        if lhs.conversation.getType() == rhs.conversation.getType() {
            return lhs.conversation.getReceiver() == rhs.conversation.getReceiver()
        }
        return lhs.conversation == rhs.conversation
    }
    
    /// 获取会话人，单聊为对方账号，群聊为群组Id
    public var receiverId: String {
        return conversation.getReceiver()
    }
    
    /// 会话类型
    public var type: TIMConversationType {
        return conversation.getType()
    }
    
    /// 加载最新一条消息
    /// 在收到推送消息过来的时候,如果没有lastMessage,就手动检索本地最新消息
    public var getLastMessage: String? {
        
        if self.lastMessage != nil { return lastMessage?.messageTip }
        
        guard let msgs = conversation.getLastMsgs(1) as? [TIMMessage] else { return nil }
        
        let elem = msgs.map{ return MessageElem(message: $0) }.first(where: {
            return $0.messageTip?.isEmpty == false
        })
        
        return elem?.messageTip
    }
    
    /// 未读消息数
    public var unreadMessageCount: Int {
        return Int(conversation.getUnReadMessageNum())
    }
}




