//
//  ChatManager.swift
//  ZebraKing
//
//  Created by 武飞跃 on 2017/9/11.
//  Copyright © 2017年 武飞跃. All rights reserved.
//

import UIKit
import ImSDK
import IMMessageExt

public enum IMError: Error {
    case loginFailure       //登录失败
    case logoutFailure      //退出登录失败
    case unknown                //未知错误
    case getUsersProfileFailure //获取用户资料失败
    case unwrappedUsersProfileFailure //转换用户资料失败
    case getHostProfileFailure //获取本地用户资料失败
}

public enum IMResult<T> {
    case success(T)
    case failure(IMError)
}

extension IMResult {
    var value: T? {
        if case .success(let v) = self {
            return v
        }
        return nil
    }
}

extension IMError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .loginFailure:
            return "聊天模块初始化失败, 请重新启动"
        case .logoutFailure:
            return "退出登录失败, 请稍后重试"
        case .unknown:
            return "发生未知错误, 请联系客服"
        case .getUsersProfileFailure:
            return "拉取用户资料失败"
        case .unwrappedUsersProfileFailure:
            return "未知错误(用户资料解包失败)"
        case .getHostProfileFailure:
            return "获取本地用户资料失败"
        }
    }
}

public protocol ZebraKingDelegate: NSObjectProtocol {
    func onResponseNotification(_ notification: ChatNotification)
}

public final class IMChatManager: NSObject {
    
    public static var `default` = IMChatManager()
    public weak var delegate: ZebraKingDelegate?

    public var loginManager: IMLoginManager = IMLoginManager()
    public var userManager: UserManager = UserManager()
    public var conversationManager = IMConversationManager()
    
    /// 基本配置
    public func register(accountType: String, appidAt3rd: String){
        loginManager.register(appidAt3rd: appidAt3rd, accountType: accountType)
    }
    
    /// 登录
    ///
    /// - Parameters:
    ///   - sign: 认证用户的唯一标示
    ///   - userId: 用户Id, 用来确认用户的角色
    ///   - facePath: 头像, 最好传进来
    ///   - nickName: 昵称, 同上
    ///   - successCompletion: 登录成功的回调
    ///   - failCompletion: 登录失败的回调
    public func login(sign: String, userId: String, result: ((IMResult<Bool>) -> Void)? = nil) {
        
        //添加监听和移除监听要合理添加
//        conversationManager.addListener()
        
        loginManager.login(identifier: userId, userSig: sign) { [weak self] (r) in
            
            switch r {
            case .success:
                
                self?.userManager.createAccountIfNotFound(id: userId)
                
                //更新会话管理中,预先出现的监听
                self?.conversationManager.retryListenerUnReadcountIfNeeded()
                
                ///   - receiverId: 会话对象的id
                ///   - content: 会话对象发送过来的聊天内容
                ///   - isChatting: 是否正与会话对象聊天中(对话窗口激活状态)
                self?.conversationManager.onResponseNotification = { (receiverId: String, content: String?, isChatting: Bool) in
                    let sender = self?.userManager.friendsList[receiverId] ?? Sender(id: receiverId)
                    let notification = ChatNotification(receiver: sender, content: content, isChatting: isChatting)
                    self?.delegate?.onResponseNotification(notification)
                }
                
                result?(.success(true))
                
            case .failure(let error):
                result?(.failure(error))
            }
        }
        
    }
    
    public func setToken(_ token: Data, busiId: UInt32) {
        let config = TIMAPNSConfig()
        config.openPush = 1
        TIMManager.sharedInstance()?.setAPNS(config, succ: {
            print("设置APNS成功")
        }, fail: { (code, stri) in
            print("APNS失败:\(stri)")
        })
        
        let tokenParam = TIMTokenParam()
        tokenParam.token = token
        tokenParam.busiId = busiId
        TIMManager.sharedInstance()?.setToken(tokenParam, succ: {
            print("设置Token成功")
        }, fail: { (code, str) in
            print("Token失败:\(str)")
        })
    }
    
    
    /// 登出
    ///
    /// - Parameter fail: 登出失败的回调
    public func logout(result: ((IMResult<Bool>) -> Void)? = nil) {
        
        /// 移除消息监听
        conversationManager.removeListener()

        loginManager.logout(success: { [weak self] in
            
            /// 清空本机用户数据
            self?.userManager.free()
            result?(.success(true))
            
            }, fail: { (_, string) in
                result?(.failure(.logoutFailure))
        })
        
    }
    
    /// 监听指定会话的未读消息数
    public func listenerUnReadcount(with id: String, completion:@escaping CountCompletion) {
        conversationManager.listenerUnReadcount(with: id, completion: completion)
    }
    
    /// 移除对会话消息数量改变的监听
    public func removeListenerUnReadcount(with id: String) {
        conversationManager.removeListenerUnReadcount(with: id)
    }
    
    /// 获取所有会话的未读消息数
    public func unReadCountAllconversation() -> Int32 {
        return conversationManager.conversationList.reduce(into: 0, { (result, converstion) in
            result += converstion.conversation.getUnReadMessageNum()
        })
    }
    
    /// 仅在重构IMChatViewController类中调用, 获取会话对象
    public func chat(with id: String) -> IMConversation? {
        return conversationManager.chat(with: id)
    }
    
    /// 仅在重构IMChatViewController类中调用, 释放会话对象
    public func releaseConversation() {
        conversationManager.releaseConversation()
    }
    
}

