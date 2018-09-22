//
//  ZebraKing.swift
//  ZebraKing
//
//  Created by 武飞跃 on 2017/9/11.
//  Copyright © 2017年 武飞跃. All rights reserved.
//

open class ZebraKing {
    
    /// 初始化配置
    ///
    /// - Parameters:
    ///   - config: 必要的配置项
    ///   - delegate: 消息通知的代理
    open static func register(config: ZebraKingUserConfig, delegate: ZebraKingDelegate){
        IMChatManager.default.register(config: config)
        IMChatManager.default.delegate = delegate
    }
    
    
    /// 登录(账号由服务器配置, 在客户端不存在注册IM账号)
    ///
    /// - Parameters:
    ///   - sign: 服务器分配的签名
    ///   - userId: 服务器分配的用户id
    ///   - result: 登录结果的回调
    open static func login(sign: String, userId: String, result: ((IMResult<Bool>) -> Void)? = nil) {
        IMChatManager.default.login(sign: sign, userId: userId, result: result)
    }
    
    /// 开始聊天
    ///
    /// - Parameters:
    ///   - id: 为对方用户 identifier
    ///   - result: 返回结果, .success: 会话对象  .failure: 提示出错的log
    open static func chat(id: String, result: @escaping (IMResult<Conversation>) -> Void) {
        chat(receiver: Sender(id: id), result: result)
    }
    
    
    /// 开始聊天
    ///
    /// - Parameters:
    ///   - notification: 内部传出来的通知模型
    ///   - result: 返回结果 .success: 会话对象  .failure: 提示出错的log
    open static func chat(notification: ChatNotification, result: @escaping (IMResult<Conversation>) -> Void) {
        chat(receiver: notification.receiver, result: result)
    }
    
    
    /// 开始聊天
    ///
    /// - Parameters:
    ///   - receiver: 聊天的对象模型, 必要的参数是id
    ///   - result: 返回结果 .success: 会话对象  .failure: 提示出错的log
    open static func chat(receiver: Sender, result: @escaping (IMResult<Conversation>) -> Void) {
        checkLoginStatus { (r) in
            
            switch r {
            case .success(_):
                
                /// 获取会话对象的资料
                var tempReceiver: Sender {
                    //缺失必要的资料就到缓存中再拉取一次
                    if receiver.isLossNecessary {
                        if let cacheReceiver = IMChatManager.default.userManager.fetchSender(id: receiver.id) {
                            return cacheReceiver
                        }
                    }
                    return receiver
                }
                
                /// 判断已登录状态, 就可以判定是调用了Login方法, 因为初始化host对象在login方法中进行的
                let host = IMChatManager.default.userManager.host!
                
                // 用于发起聊天的会话对象
                let task = IMChatManager.default.chat(with: receiver.id)
                
                if let unwrappedTask = task {
                    let conversation = Conversation(host: host, receiver: tempReceiver, task: unwrappedTask)
                    result(.success(conversation))
                }
                else {
                    result(.failure(.unknown))
                }
                
            case .failure(let error):
                result(.failure(error))
            }
            
        }
    }
    
    private static func checkLoginStatus(result: @escaping (IMResult<Bool>) -> Void) {
        //判断是否是已登录状态
        if IMLoginManager.isLoginSuccessed {
            result(.success(true))
        }
        else {
            IMChatManager.default.loginManager.relogin(result: { (r) in
                switch r {
                case .success:
                    result(.success(true))
                case .failure(_):
                    result(.failure(.loginFailure))
                }
            })
        }
    }
    
}
