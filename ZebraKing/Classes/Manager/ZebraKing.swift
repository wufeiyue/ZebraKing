//
//  ZebraKing.swift
//  ZebraKing
//
//  Created by 武飞跃 on 2017/9/11.
//  Copyright © 2017年 武飞跃. All rights reserved.
//

import Foundation
import IMMessageExt

open class ZebraKing {
    
    
    /// 初始化配置
    ///
    /// - Parameters:
    ///   - config: 必要的配置项
    ///   - delegate: 消息通知的代理
    public static func register(accountType: String, appidAt3rd: Int32, completion: @escaping (ChatNotification) -> Void){
        SessionManager.default.register(accountType: accountType, appidAt3rd: appidAt3rd, completion: completion)
    }

    
    /// 登录(账号由服务器配置, 在客户端不存在注册IM账号)
    ///
    /// - Parameters:
    ///   - sign: 服务器分配的签名
    ///   - userId: 服务器分配的用户id
    ///   - result: 登录结果的回调
    public static func login(sign: String, userId: String, appidAt3rd: String, result: @escaping (Result<Void>) -> Void) {
        SessionManager.default.login(sign: sign, userId: userId, appidAt3rd: appidAt3rd, result: result)
    }
    
    
    /// 退出登录
    ///
    /// - Parameter result: 结果
    public static func logout(result: @escaping (Result<Void>) -> Void) {
        SessionManager.default.logout(result: result)
    }
    
    /// 开始聊天
    ///
    /// - Parameters:
    ///   - id: 为对方用户 identifier
    ///   - result: 返回结果, .success: 会话对象  .failure: 提示出错的log
    public static func chat(id: String, configuration: Task.Configuration = .default, result: @escaping (Result<Task>) -> Void) {
        chat(receiver: Sender(id: id), configuration: configuration, result: result)
    }
    
    
    /// 开始聊天
    ///
    /// - Parameters:
    ///   - receiver: 聊天的对象模型, 必要的参数是id
    ///   - result: 返回结果 .success: 会话对象  .failure: 提示出错的log
    public static func chat(receiver: Sender, configuration: Task.Configuration = .default, result: @escaping (Result<Task>) -> Void) {
        SessionManager.default.chat(receiver: receiver, configuration: configuration, result: result)
    }
    
    
    /// 移除会话, 并清空消息记录
    ///
    /// - Parameter id: 会话id, 仅支持C2C
    public static func deleteConversation(where rule: (Conversation) throws -> Bool) rethrows {
        try SessionManager.default.deleteConversation(where: rule)
    }
    
}

//MARK: - CentralManager
extension ZebraKing {
    
    /// 监听指定会话的未读消息数 如果消息回调结果为nil, 表示没有获取会话, 可能是没有登录成功
    public static func listenerUnreadMessage(with id: String, completion:@escaping CentralManager.CountCompletion) {
        SessionManager.default.listenerUnreadMessage(id: id, completion: completion)
    }
    
    /// 移除对会话消息数量改变的监听
    @available(*, deprecated, renamed: "removeUnReadMessageListener")
    public static func removeListenerUnreadMessage(id: String) {
        SessionManager.default.removeListenerUnreadMessage()
    }
    
    public static func removeUnReadMessageListener() {
        SessionManager.default.removeListenerUnreadMessage()
    }
}

//MARK: - UserManager
extension ZebraKing {
    
    /// 修改我的昵称
    ///
    /// - Parameter nickName: 昵称
    public static func updateHostProfile(nickName: String,
                                         result: @escaping (Swift.Result<String, ZebraKingError>) -> Void) {
        SessionManager.default.modifySelfNickname(nickName, result: result)
    }
    
    /// 修改我的头像
    ///
    /// - Parameter path: 头像地址(服务器存放图片的地址)
    public static func updateHostProfile(avatar: String,
                                         result: @escaping (Swift.Result<String, ZebraKingError>) -> Void) {
        SessionManager.default.modifySelfFacePath(avatar, result: result)
    }
    
    @available(*, deprecated, renamed: "updateHostProfile")
    public static func modifySelfNickname(_ nickName: String) {
        SessionManager.default.modifySelfNickname(nickName, result: { _ in
            
        })
    }
    
    @available(*, deprecated, renamed: "updateHostProfile")
    public static func modifySelfFacePath(path: String) {
        SessionManager.default.modifySelfFacePath(path, result: { _ in
            
        })
    }
}
