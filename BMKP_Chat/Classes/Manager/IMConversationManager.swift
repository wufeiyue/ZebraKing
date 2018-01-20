//
//  IMConversationManager.swift
//  BMKP
//
//  Created by 武飞跃 on 2017/9/11.
//  Copyright © 2017年 bmkp. All rights reserved.
//

import Foundation
import ImSDK
import IMMessageExt

public final class IMConversationManager: NSObject {
    
    public var sendLocalNotification:((NotificationModel) -> Void)?
    private(set) var conversationList = Set<IMConversation>()             //会话消息集合
    private(set) var userModelList = Dictionary<String, IMUserModel>()   //用户信息存储集合
    private var chattingConversation: IMConversation? //活跃的会话对象, 仅当调用chat方法时,跳转IMChatViewController页面此时会话为chattingViewConversation,在onNewMessage回调方法中,监听当前页面的消息,然后会在页面Disappear时,移除该会话的消息监听
    private var listenerList = Dictionary<IMChatUnit, CountCompletion>() //用户会话消息数监听
    
    override public init() {
        super.init()
        addListener()
    }
    
    //唯一的聊天入口,传入聊天对象的类型及Id
    public func chat(with model: IMChatUnit) -> IMConversation? {
        
        if let conversation = getConversationAndCreateIfNotFound(by: model) {
            chattingConversation = conversation
        }
        
        return chattingConversation
    }
    
    public func addListener() {
        //消息监听
        TIMManager.sharedInstance().add(self)
    }
    
    public func removeListener() {
        TIMManager.sharedInstance().remove(self)
        TIMManager.sharedInstance().getUserConfig().receiptListener = nil
    }
    
    /// 清空_conversationlist，并删除所有SDK存储的会话和消息
    public func deleteAllconversation(){
        conversationList.forEach({ delete(with: $0) })
    }
    
    //删除所有用户之间的会话
    public func deleteAllUserconversation() {
        conversationList.forEach({
            //移除所有用户会话
            if IMChatRole.convert($0.conversation.getReceiver()) != .server {
                delete(with: $0)
            }
        })
    }
    
    //删除会话记录
    public func deleteMessage(with model: IMChatUnit) {
        if let conv = getConversation(by: model) {
            conv.deleteLocalMessage()
        }
    }
    
    public func delete(model: IMChatUnit) {
        if let conv = getConversation(by: model) {
            delete(with: conv)
        }
    }
    
    public func delete(with conversation: IMConversation) {
        conversation.deleteConversation()
        conversationList.remove(conversation)
    }
    
    /// 本来是交给IMChatViewController释放conversation的, 可是由于单例的原因,在IMChatViewController中释放不了conversation, conversation还必须得到释放,否则影响"未读/已读"状态
    public func releaseConversation() {
        chattingConversation?.releaseConversation()
        chattingConversation = nil
    }
    
    /// 查看会话类型的未读消息数
    ///
    /// - Parameter type: 会话类型
    /// - Returns: 未读消息数
    private func unReadCount(withConversation model: IMChatUnit) -> Int {
        guard let con = getConversation(by: model) else {
            return 0
        }
        return Int(con.conversation.getUnReadMessageNum())
    }
    
    //根据会话类型监听此会话的未读消息数
    public func listenerUnReadcount(with model: IMChatUnit, completion:@escaping CountCompletion) {
        let conversation = getConversationAndCreateIfNotFound(by: model)
        completion(unReadCount(withConversation: model))
        dispatch_async_safely_to_main_queue {
            conversation?.unReadCountCompletion = completion
        }
        if conversation == nil {
            listenerList[model] = completion
        }
    }
    
    public func removeListenerUnReadcount(with model: IMChatUnit) {
        let conversation = getConversation(by: model)
        //TODO: 外面使用此方法监听消息数,必须为弱引用, 否则会造成内存泄漏,严重会crash在这里, 后期会增加优化方法, 现在可以正常使用
        conversation?.unReadCountCompletion = nil
        listenerList.removeValue(forKey: model)
    }
    
    //检查未读消息是否被有效的监听,因为可能出现用户在未登录的情况下,监听已经执行了,这样势必会因为未登录原因,获取不到会话对象, 造成监听无效, 所以需要在出现未登录情况下,将初始会话消息IMChatUnit暂存起来,等用户登录成功以后,启用之前的监听
    public func retryListenerUnReadcountIfNeeded() {
        listenerList.forEach { (chatUnit, completion) in
            if let conversation = getConversationAndCreateIfNotFound(by: chatUnit) {
                //FIXME: 这可能有个坑,在重复调用此方法时, completion本来有值,会给整没了,待观察
                conversation.unReadCountCompletion = completion
                listenerList.removeValue(forKey: chatUnit)
            }
        }
    }
    
    /// 对方是否从未发消息给我过 (判断依据是对方没有出现在会话列表中, 或者 用于保存对方消息推送的lastMessage为nil)
    public func isNeverChat(_ chatUnit: IMChatUnit) -> Bool {
        if let conversation = getConversation(by: chatUnit) {
            return conversation.isNeverChat
        }
        return true
    }
    
    //获取存在于集合中的会话
    private func getConversation(by model: IMChatUnit) -> IMConversation? {
        
        let id = model.id
        
        if let conversation = conversationList.filterFirst(rule: { $0.conversation.getReceiver() == id }) {
            return conversation
        }
        
        return nil
    }
    
    //获取会话  如果当前列表中不存在此会话 就会自动创建一个会话
    private func getConversationAndCreateIfNotFound(by model: IMChatUnit) -> IMConversation? {
        
        let id = model.id
        
        if let conversation = conversationList.filterFirst(rule: { $0.conversation.getReceiver() == id }) {
            return conversation
        }else if let conversation = TIMManager.sharedInstance().getConversation(.C2C, receiver: id ) {
            let temp = IMConversation(conversation: conversation)
            conversationList.insert(temp)
            return temp
        }
        
        return nil
    }
    
}


extension IMConversationManager: TIMMessageListener {
    //监听消息
    public func onNewMessage(_ msgs: [Any]!) {
        guard let messages = msgs as? [TIMMessage] else { return }
        
        for message in messages {
            
            guard let imMessage = IMMessage.msgWith(msg: message),
                let currentConversation = imMessage.msg.getConversation() else{ continue }
            
            //仅对用户与用户消息处理
            if currentConversation.getType() == .C2C {
                //此会话是否存在聊天列表中
                if let unwrappedConversation = conversationList.filterFirst(rule: { $0.conversation.getReceiver() == currentConversation.getReceiver() }) {
                    //接收消息监听,为了对比时间,需要放在lastMessage复制前
                    chattingConversation?.onReceiveMessageCompletion?(imMessage)
                    //将接收到的消息作为最新一条消息
                    unwrappedConversation.set(lastMessage: imMessage)
                    //此消息的会话对象是否对应当前聊天对象,根据此来判断对方是否"正在输入中"
                    if currentConversation.getReceiver() == chattingConversation?.getReceiver() {
                        //消息发出者是否由对方发出
                        if !message.isSelf() {
                            unwrappedConversation.alreadyRead(message:imMessage)
                            if case .background = UIApplication.shared.applicationState {
                                handlerChattingConversationNotification(with: unwrappedConversation)
                            }
                        }
                    }
                    else {
                        //不是当前的聊天对象
                        if imMessage.isMineMsg == false {
                            handlerNoExistListNotification(with: unwrappedConversation)
                        }
                    }
                }
                else {
                    //新的会话不在列表中,可能是对方先发起的聊天,需要插入到会话列表中
                    let temp = IMConversation(conversation: currentConversation)
                    temp.set(lastMessage: imMessage)
                    conversationList.insert(temp)
                    handlerNoExistListNotification(with: temp)
                }
            }
        }
        
    }
    
    //处理当前会话通知
    private func handlerChattingConversationNotification(with conversation: IMConversation) {
        
        guard let receiver = IMChatRole.convert(conversation.conversation.getReceiver()) else { return }
        
        let messageTip = conversation.getLastMessage()?.messageTip
        
        switch receiver {
        case .server:
            let model = NotificationModel(title: receiver.simpleName(with: ""), content: messageTip, userModel: .server)
            sendLocalNotification?(model)
        default:
            queryUserInfo(conversation: conversation, result: { user in
                let model = NotificationModel(title: receiver.simpleName(with: user.nickName), content: messageTip, userModel: user)
                self.sendLocalNotification?(model)
            })
        }
        
    }
    
    //处理不是当前会话的通知
    private func handlerNoExistListNotification(with conversation: IMConversation) {
        
        guard let receiver = IMChatRole.convert(conversation.conversation.getReceiver()) else {
            return
        }
        
        let messageTip = conversation.getLastMessage()?.messageTip
        
        switch receiver {
        case .server:
            let model = NotificationModel(title: receiver.simpleName(with: ""), content: messageTip, icon: receiver.imageName, placeholder:receiver.imageName, userModel: .server, notificationName:.didRecievedServerMessage)
            sendLocalNotification?(model)
        case .driver:
            queryUserInfo(conversation: conversation, result: { user in
                let model = NotificationModel(title: receiver.simpleName(with: user.nickName), content: messageTip, icon: user.facePath, placeholder:receiver.imageName, userModel: user, notificationName: .didRecievedDriverMessage)
                self.sendLocalNotification?(model)
            })
        case .passenger:
            queryUserInfo(conversation: conversation, result: { user in
                let model = NotificationModel(title: receiver.simpleName(with: user.nickName), content: messageTip, icon: user.facePath, placeholder:receiver.imageName, userModel: user, notificationName: .didRecievedPassengerMessage)
                self.sendLocalNotification?(model)
            })
        }
        
        conversation.addUnReadCount()
    }
    
    /// 获取用户资料
    ///
    /// - Parameters:
    ///   - userId: 用户id
    ///   - result: 回调结果 IMUserModel
    public func queryUserInfo(userId: String, result :@escaping (IMUserModel) -> Void) {
        
        TIMFriendshipManager.sharedInstance()?.getUsersProfile([userId], succ: { profile in
            
            if let unwrappedProfile = profile?.first as? TIMUserProfile {
                let model = IMUserModel(id: unwrappedProfile.identifier, facePath: unwrappedProfile.faceURL, nickName: unwrappedProfile.nickname)
                self.userModelList[userId] = model
                result(model)
            }
            
        }, fail: { (code , str) in
            let model = IMUserModel(userId: userId)
            result(model)
        })
    }
    
    private func queryUserInfo(conversation: IMConversation, result :@escaping (IMUserModel) -> Void) {
        let id = conversation.getReceiver()
        if let user = userModelList[id], user.isLoseMustInfo == false {
            result(user)
            return
        }
        queryUserInfo(userId: id, result: result)
    }

}

public struct NotificationModel {
    public var title: String
    public var content: String
    public var icon: String?
    public var placeholder: String?
    public var userInfo: [AnyHashable:Any]?
    public var tapAction: (()->Void)?
    public var notificationName:Notification.Name?
    public init(title: String, content:String?, icon:String? = nil, placeholder: String? = nil,  userModel: IMUserModel, notificationName: Notification.Name? = nil) {
        self.title = title
        self.content = content ?? "给你发送了一条消息"
        self.icon = icon
        self.placeholder = placeholder
        self.userInfo = ["id": userModel.id, "facePath": userModel.facePath ?? "", "nickName": userModel.nickName]
        self.notificationName = notificationName
    }
}

