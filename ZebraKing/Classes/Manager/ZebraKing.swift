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
    public static func register(accountType: String, appidAt3rd: String, delegate: ZebraKingDelegate){
        IMChatManager.default.register(accountType: accountType, appidAt3rd: appidAt3rd)
        IMChatManager.default.delegate = delegate
    }
    
    public static func setToken(_ token: Data, busiId: UInt32) {
        IMChatManager.default.setToken(token, busiId: busiId)
    }
    
    /// 登录(账号由服务器配置, 在客户端不存在注册IM账号)
    ///
    /// - Parameters:
    ///   - sign: 服务器分配的签名
    ///   - userId: 服务器分配的用户id
    ///   - result: 登录结果的回调
    public static func login(sign: String, userId: String, result: ((IMResult<Bool>) -> Void)? = nil) {
        IMChatManager.default.login(sign: sign, userId: userId, result: result)
    }
    
    
    /// 退出登录
    ///
    /// - Parameter result: 结果
    public static func logout(result: ((IMResult<Bool>) -> Void)? = nil) {
        IMChatManager.default.logout(result: result)
    }
    
    /// 开始聊天
    ///
    /// - Parameters:
    ///   - id: 为对方用户 identifier
    ///   - result: 返回结果, .success: 会话对象  .failure: 提示出错的log
    public static func chat(id: String, result: @escaping (IMResult<Conversation>) -> Void) {
        chat(receiver: Sender(id: id), result: result)
    }
    
    
    /// 开始聊天
    ///
    /// - Parameters:
    ///   - notification: 内部传出来的通知模型
    ///   - result: 返回结果 .success: 会话对象  .failure: 提示出错的log
    public static func chat(notification: ChatNotification, result: @escaping (IMResult<Conversation>) -> Void) {
        chat(receiver: notification.receiver, result: result)
    }
    
    
    /// 开始聊天
    ///
    /// - Parameters:
    ///   - receiver: 聊天的对象模型, 必要的参数是id
    ///   - result: 返回结果 .success: 会话对象  .failure: 提示出错的log
    public static func chat(receiver: Sender, result: @escaping (IMResult<Conversation>) -> Void) {
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
                guard let host = IMChatManager.default.userManager.host else {
                    result(.failure(.getHostProfileFailure))
                    return
                }
                
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
    
    /// 监听指定会话的未读消息数
    public static func listenerUnReadcount(with id: String, completion:@escaping CountCompletion) {
        IMChatManager.default.listenerUnReadcount(with: id, completion: completion)
    }
    
    /// 移除对会话消息数量改变的监听
    public static func removeListenerUnReadcount(with id: String) {
        IMChatManager.default.removeListenerUnReadcount(with: id)
    }
    
    /// 获取所有会话的未读消息数
    public static func unReadCountAllconversation() -> Int32 {
        return IMChatManager.default.unReadCountAllconversation()
    }
    
    /// 修改我的昵称
    ///
    /// - Parameter nickName: 昵称
    public static func modifySelfNickname(_ nickName: String) {
        IMChatManager.default.userManager.modifySelfNickname(nickName)
    }
    
    /// 修改我的头像
    ///
    /// - Parameter path: 头像地址(服务器存放图片的地址)
    public static func modifySelfFacePath(path: String) {
        IMChatManager.default.userManager.modifySelfFacePath(path)
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
