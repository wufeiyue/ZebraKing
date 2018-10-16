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
    private var centralManager = CentralManager()
    
    //用户管理中心
    private var userManager = UserManager()
    
    //用户登录中心
    private var loginManager = LoginManager()
    
    //单例模式
    public static var `default` = SessionManager()
    
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
    public func login(sign: String, userId: String, appidAt3rd: String, result: @escaping (IMResult<Bool>) -> Void) {
        
        loginManager.appidAt3rd = appidAt3rd
        loginManager.userSig = sign
        loginManager.identifier = userId
        
        loginManager.login() {
            switch $0 {
            case .success:
                //创建自己的主机账户
                self.userManager.createAccount(id: userId)
                result(.success(true))
            case .failure:
                result(.failure(.loginFailure))
            }
        }
        
    }
    
    /// 退出登录
    public func logout(result: @escaping (IMResult<Bool>) -> Void) {
        loginManager.logout(success: {
            
            self.userManager.free()
            self.centralManager.removeListenerMessage()
            
            result(.success(true))
            
        }) { (code, str) in
            //TODO: 退出登录失败
            result(.failure(.logoutFailure))
        }
    }
    
    //根据聊天对象的Id监听其发过来的未读消息数
    public func listenerUnreadMessage(id: String, completion: @escaping CountCompletion) {
        centralManager.listenerUnReadCount(with: .C2C, id: id, completion: completion)
    }
    
    //移除未读消息监听
    public func removeListenerUnreadMessage() {
        centralManager.removeListenerUnReadCount()
    }
    
    /// 发起聊天
    ///
    /// - Parameters:
    ///   - receiver: 会话对象
    ///   - result: 返回用于ConversationViewController(task: Task)构造聊天类的Task对象
    public func chat(receiver: Sender, result: @escaping (IMResult<Task>) -> Void) {
        
        //如果已经登录, 就直接返回成功的结果, 可以解决RxSwift合并流
        loginManager.login() {
            
            switch $0 {
            case .success(_):
                
                /// 判断已登录状态, 就可以判定是调用了Login方法, 因为初始化host对象在login方法中进行的
                guard let host = self.userManager.host else {
                    result(.failure(.getHostProfileFailure))
                    return
                }
                
                var tempReceiver: Sender = receiver
                
                //资料是否完整
                if receiver.isLossNecessary {
                    //缺失必要的资料就到缓存中再拉取一次
                    if let cacheReceiver = self.userManager.getSender(id: receiver.id) {
                        tempReceiver = cacheReceiver
                    }
                }
                
                // 用于发起聊天的会话对象
                let converstion = self.centralManager.holdChat(with: .C2C, id: receiver.id)
                
                if let unwrappedConversation = converstion {
                    let task = Task(host: host, receiver: tempReceiver, conversation: unwrappedConversation)
                    result(.success(task))
                }
                else {
                    result(.failure(.unknown))
                }
                
            case .failure(let error):
                result(.failure(error))
            }
            
        }
    }
    
    //开启消息监听, 避免消息监听遗漏, 要放在登录方法调用之前
    private func onResponseNotification(completion: @escaping (ChatNotification) -> Void) {
        
        centralManager.listenterMessages{ (receiverId, content) in
            
            self.userManager.queryFriendProfile(id: receiverId, result: { result in
                
                var sender: Sender {
                    if case .success(let value) = result {
                        return value
                    }
                    else {
                        return Sender(id: receiverId)
                    }
                }
                
                let notification = ChatNotification(receiver: sender, content: content)
                completion(notification)
            })
            
        }
    }
    
    //FIXME: - 释放活跃得会话
    public func waiveChat() {
        centralManager.waiveChat()
    }
    
    public func deleteConversation(with type: TIMConversationType, id: String) {
        centralManager.deleteConversation(with: type, id: id)
    }
    
}
extension SessionManager {
    
    /// 修改我的昵称
    public func modifySelfNickname(_ nick : String) {
        userManager.modifySelfNickname(nick)
    }
    
    /// 修改自己的头像
    public func modifySelfFacePath(_ path : String) {
        userManager.modifySelfFacePath(path)
    }
 
    public func queryFriendProfile(id: String, result: @escaping (IMResult<Sender>) -> Void) {
        userManager.queryFriendProfile(id: id, result: result)
    }
}
