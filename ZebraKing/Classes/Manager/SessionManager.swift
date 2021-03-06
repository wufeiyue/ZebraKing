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

open class SessionManager {
    
    //会话管理中心
    internal var centralManager = CentralManager()
    
    //用户管理中心
    internal var userManager = UserManager()
    
    //用户登录中心
    internal var loginManager = LoginManager()
    
    //单例模式
    public static var `default` = SessionManager()
    
    //存在于列表中的所有会话
    public var conversationList: Set<Conversation> {
        return centralManager.conversationList
    }
    
    //处于会话页面时, 是否将通知来的消息, 自动设置为已读
    public var isAutoDidReadedWhenReceivedMessage: Bool = true {
        didSet {
            centralManager.isAutoDidReadedWhenReceivedMessage = isAutoDidReadedWhenReceivedMessage
        }
    }
    
    required public init() { }
    
    /// 初始化注册
    public func register(accountType: String, appidAt3rd: Int32, completion: @escaping (ChatNotification) -> Void){
        
        let sdkConfig = TIMSdkConfig()
        sdkConfig.sdkAppId = appidAt3rd
        sdkConfig.accountType = accountType
        sdkConfig.disableLogPrint = true //禁止在控制台打印
        TIMManager.sharedInstance().initSdk(sdkConfig)
        
        let userConfig = TIMUserConfig()
        userConfig.enableReadReceipt = true //开启已读回执
        userConfig.disableRecnetContact = true //不开启最近联系人
        TIMManager.sharedInstance().setUserConfig(userConfig)
        
        onResponseNotification(completion: completion)
        
    }
    
    /// 登录(账号由服务器配置, 在客户端不存在注册IM账号)
    ///
    /// - Parameters:
    ///   - sign: 服务器分配的签名
    ///   - userId: 服务器分配的用户id
    ///   - result: 登录结果的回调
    public func login(sign: String, userId: String, appidAt3rd: String, result: @escaping (Result<Void>) -> Void) {
        
        loginManager.appidAt3rd = appidAt3rd
        loginManager.userSig = sign
        loginManager.identifier = userId
        
        loginManager.login() {
            switch $0 {
            case .success:
                self.centralManager.addListenter()
                result(.success(()))
            case .failure:
                result(.failure(.loginFailure))
            }
        }
        
    }
    
    /// 退出登录
    public func logout(result: @escaping (Result<Void>) -> Void) {
        loginManager.logout(success: {
            
            self.userManager.free()
            self.centralManager.removeListener()
            
            result(.success(()))
            
        }) { (code, str) in
            //TODO: 退出登录失败
            result(.failure(.logoutFailure))
        }
    }
    
    //根据聊天对象的Id监听其发过来的未读消息数
    public func listenerUnreadMessage(id: String, completion: @escaping CentralManager.CountCompletion) {
        centralManager.listenerUnReadCount(with: .C2C, id: id, completion: completion)
    }
    
    //移除未读消息监听
    public func removeListenerUnreadMessage() {
        centralManager.removeUnReadCountListenter()
    }
    
    /// 发起聊天
    ///
    /// - Parameters:
    ///   - receiver: 会话对象
    ///   - result: 返回用于ConversationViewController(task: Task)构造聊天类的Task对象
    public func chat(receiver: Sender, configuration: Task.Configuration, result: @escaping (Result<Task>) -> Void) {
        
        loginManager.login() { [unowned self] in
            
            switch $0 {
            case .success(_):
                
                // 用于发起聊天的会话对象
                let converstion = self.centralManager.holdChat(with: .C2C, id: receiver.id)
                guard let unwrappedConversation = converstion else {
                    result(.failure(.unknown))
                    return
                }
                
                self.userManager.getHost(result: { (r) in
                    switch r {
                    case let.success(sender):
                        
                        let task = Task(host: sender,
                                        receiver: receiver,
                                        conversation: unwrappedConversation,
                                        configuration: configuration)
                        
                        result(.success(task))
                    case .failure(let error):
                        result(.failure(error))
                    }
                })
                
            case .failure(let error):
                result(.failure(error))
            }
        }
    }
    
    public func deleteConversation(where rule: (Conversation) throws -> Bool) rethrows {
        try centralManager.deleteConversation(where: rule)
    }
    
    //开启消息监听, 避免消息监听遗漏, 要放在登录方法调用之前
    private func onResponseNotification(completion: @escaping (ChatNotification) -> Void) {
        
        centralManager.listenterMessages{ [unowned self] (receiverId, content, unreadCount) in
            
            self.userManager.queryFriendProfile(id: receiverId, result: { result in
            
                var sender: Sender {
                    if case .success(let value) = result {
                        return value
                    }
                    else {
                        return Sender(id: receiverId)
                    }
                }
                
                let notification = ChatNotification(receiver: sender, content: content, unreadCount: unreadCount)
                completion(notification)
            })
            
        }
    }
    
    //FIXME: - 释放活跃得会话
    public func waiveChat() {
        centralManager.waiveChat()
    }
    
    
}
extension SessionManager {
    
    /// 修改我的昵称
    public func modifySelfNickname(_ nick : String,
                                   result: @escaping (Swift.Result<String, ZebraKingError>) -> Void) {
        userManager.modifySelfNickname(nick, result: result)
    }
    
    /// 修改自己的头像
    public func modifySelfFacePath(_ path : String,
                                   result: @escaping (Swift.Result<String, ZebraKingError>) -> Void) {
        userManager.modifySelfFacePath(path, result: result)
    }
 
    public func queryFriendProfile(id: String, result: @escaping (Result<Sender>) -> Void) {
        userManager.queryFriendProfile(id: id, result: result)
    }
    
    public func getHost(result: @escaping (Result<Sender>) -> Void) {
        userManager.getHost(result: result)
    }
}
