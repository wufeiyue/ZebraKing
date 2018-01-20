//
//  ChatManager.swift
//  BMKP
//
//  Created by 武飞跃 on 2017/9/11.
//  Copyright © 2017年 武飞跃. All rights reserved.
//

import UIKit
import ImSDK
import IMMessageExt

public final class IMChatManager: NSObject {
    
    public private(set) var host: IMUserUnit?
    public static var `default` = IMChatManager()
    public private(set) var configuration: IMConfiguation!
    public private(set) var conversationManager = IMConversationManager()
    
    /// 基本配置
    public func register(configuration:IMConfiguation){
        self.configuration = configuration
        
        let userConfig = TIMUserConfig()
        userConfig.enableReadReceipt = true //开启已读回执
        userConfig.disableRecnetContact = true //不开启最近联系人
        
        let sdkConfig = TIMSdkConfig()
        sdkConfig.sdkAppId = Int32(configuration.appidAt3rd)!
        sdkConfig.accountType = configuration.accountType
        sdkConfig.disableLogPrint = configuration.disableLog //禁止在控制台打印
        
        TIMManager.sharedInstance().initSdk(sdkConfig)
        TIMManager.sharedInstance().setUserConfig(userConfig)
    }
    
    /// 跳转到聊天视图
    /// 每次跳转页面都需要获取一下对方的信息,这流量浪费掉了,目前的需求是这样啊
    /// - Parameters:
    ///   - unit: 完整的聊天对象 role: 对方的角色  如果不确定可以不传 这样做主要规避 如司机端id前缀不加"d"的情况
    ///   - target: 用于跳转的ViewController
    ///   - chatVC: 跳转到指定的聊天会话ViewController, 可以传入IMChatViewController
    ///   - chatTitle: 会话页面的title, 如果为nil, 则从userModel中取用户的nickName
    public func present<T: UIViewController>(chatUnit unit: IMChatUnit, target: UIViewController? = nil, chatVC: T, chatTitle: String? = nil, completion:(() -> Void)? = nil) where T: IMChattingDelegate  {
        
        guard isLogin else { relogin(); return }
        
        /*
         每次跳转页面,会因为异步查询用户信息造成不能及时打开页面, 内部逻辑优化的结果是:
         1.双方第一次聊天时, 主动给对方发消息, 这时不需要知道对方的头像,前提是昵称和ChatId通过已知数据传入. 就可以先不请求对方个人信息,
         */
//        if isNeverChat(unit) && chatTitle?.isEmpty == false {
//            let model = IMUserModel(userId: unit.id)
//            let receiver = IMUserUnit(role: unit.role, model: model)!
//            self.present(userUnit: receiver, target: target, chatVC: chatVC, chatTitle: chatTitle, completion: completion)
//        }
//        else {
            queryUserInfo(userId: unit.id) { (model) in
                if let receiver = IMUserUnit(role: unit.role, model: model) {
                    self.present(userUnit: receiver, target: target, chatVC: chatVC, chatTitle: chatTitle, completion: completion)
                }
            }
//        }
    }

    /// 跳转到聊天视图
    ///
    /// - Parameters:
    ///   - unit: 完整的用户对象
    ///   - target: 用于跳转的ViewController
    ///   - chatVC: 跳转到指定的聊天会话ViewController, 可以传入IMChatViewController
    ///   - chatTitle: 会话页面的title, 如果为nil, 则从userModel中取用户的nickName
    public func present<T: UIViewController>(userUnit unit: IMUserUnit, target: UIViewController? = nil, chatVC: T, chatTitle: String? = nil, completion:(() -> Void)? = nil) where T: IMChattingDelegate {
        
        chatVC.receiver = unit
        chatVC.chatTitle = chatTitle

        if let unwrappedTarget = target {
            let navi = UINavigationController(rootViewController: chatVC)
            unwrappedTarget.present(navi, animated: true, completion: completion)
        }
        else {
            let rootViewController = UIApplication.shared.keyWindow?.rootViewController
            
            if let tabBarController = rootViewController as? UITabBarController {
                let navi = UINavigationController(rootViewController: chatVC)
                tabBarController.selectedViewController?.present(navi, animated: true, completion: completion)
                return
            }
            let navi = UINavigationController(rootViewController: chatVC)
            rootViewController?.present(navi, animated: true, completion: completion)
        }
    }
    
    /* 中转消息推送
     private func sendLocalNotification(_ model: NotificationModel) {
         switch UIApplication.shared.applicationState {
         case .background:
             UIApplication.localNotification(title: model.title, body: model.content, userInfo : model.userInfo)
         case .active, .inactive:
             NotificationView.show(title: model.title, content: model.content, icon: model.icon, placeholder: model.placeholder, tapAction: {
                 if let name = model.notificationName {
                     NotificationCenter.default.post(name: name, object: nil, userInfo: model.userInfo)
                 }
             })
         }
     }
     */
    public func transitMessages(notification: @escaping (NotificationModel) -> Void) {
        conversationManager.sendLocalNotification = notification
    }
}

extension IMChatManager {
  
    /// 登录
    ///
    /// - Parameters:
    ///   - sign: 认证用户的唯一标示
    ///   - userId: 用户Id, 用来确认用户的角色
    ///   - facePath: 头像, 最好传进来
    ///   - nickName: 昵称, 同上
    ///   - successCompletion: 登录成功的回调
    ///   - failCompletion: 登录失败的回调
    public func login(sign:String, userId:String, facePath: String? = nil, nickName: String = "" , successCompletion:TIMSucc? = nil, failCompletion: TIMFail? = nil) {
        
        if configuration == nil { fatalError("需调用register方法完成Configuration配置") }
        
        configuration.identifier = userId
        configuration.userSig = sign
        
        let userModel = IMUserModel(id: userId, facePath: facePath, nickName: nickName)
        host = IMUserUnit(model: userModel)
        
        guard TIMManager.sharedInstance().getLoginStatus() == .STATUS_LOGOUT else { return }
        
        TIMManager.sharedInstance().login(configuration, succ: { [weak self] in
            
            //FIXME: - 同步我的个人信息, 如果外面不传facePath过来, 这里同步结果比较慢, 就会造成chatViewController个人信息显示成默认头像
            self?.updateHostProfile()
            
            //更新会话管理中,预先出现的监听
            self?.conversationManager.retryListenerUnReadcountIfNeeded()
            
            successCompletion?()
            
            }, fail: failCompletion )
    }
    
    
    /// 登出
    ///
    /// - Parameter fail: 登出失败的回调
    public func logout(failCompletion: TIMFail? = nil) {
        
        //移除配置信息
        configuration.identifier = nil
        configuration.userSig = nil
        
        TIMManager.sharedInstance().logout({ [weak self] in
            
            /// 清空本机用户数据
            self?.host = nil
            
            /// 清空本地储存的会话
            self?.conversationManager.deleteAllconversation()
            
            /// 移除消息监听
            self?.conversationManager.removeListener()
            
        }, fail: failCompletion)
    }
    
    
    /// 获取当前登陆的用户(这个方式会引起crash, TIMManager.sharedInstance().getLoginUser() == nil, 已弃用)
//    public var isLogin: Bool {
//        if let unwrapped = host {
//            return TIMManager.sharedInstance().getLoginUser() == unwrapped.model.id
//        }
//        else {
//            return false
//        }
//    }
    
    /// 是否登录
    public var isLogin: Bool {
        return TIMManager.sharedInstance().getLoginStatus() == .STATUS_LOGINED
    }
    
    
    /// 重新登录
    ///
    /// - Parameters:
    ///   - success: 成功回调  仅返回状态
    ///   - failure: 失败回调  返回失败 错误码和错误信息
    public func relogin(success: TIMSucc? = nil, failure: TIMFail? = nil) {
        if let sign = configuration.userSig, let userId = configuration.identifier {
            login(sign: sign, userId: userId, successCompletion: success, failCompletion: failure)
        }
        else {
            failure?(-1, "登录失败")
        }
    }
    
}



extension IMChatManager {
    
    /// 删除所有的会话
    public func deleteAllUserconversation() {
        conversationManager.deleteAllUserconversation()
    }
    
    /// 监听指定会话的未读消息数
    public func listenerUnReadcount(with type: IMChatUnit, completion:@escaping CountCompletion) {
        conversationManager.listenerUnReadcount(with: type, completion: completion)
    }
    
    /// 移除对会话消息数量改变的监听
    public func removeListenerUnReadcount(with type: IMChatUnit) {
        conversationManager.removeListenerUnReadcount(with: type)
    }
    
    /// 获取所有会话的未读消息数
    public func unReadCountAllconversation() -> Int32 {
        return conversationManager.conversationList.reduce(into: 0, { (result, converstion) in
            result += converstion.conversation.getUnReadMessageNum()
        })
    }
    
    /// 获取用户资料
    ///
    /// - Parameters:
    ///   - userId: 用户id
    ///   - success: 成功的回调 IMUserModel
    ///   - failure: 失败的回调 IMError
    public func queryUserInfo(userId: String, result :@escaping (IMUserModel) -> Void) {
        conversationManager.queryUserInfo(userId: userId, result: result)
    }
    
    /// 仅在重构IMChatViewController类中调用, 获取会话对象
    public func chat(with type: IMChatUnit) -> IMConversation? {
        return conversationManager.chat(with: type)
    }
    
    /// 仅在重构IMChatViewController类中调用, 释放会话对象
    public func releaseConversation() {
        conversationManager.releaseConversation()
    }
    
    /// 与对方没有聊过天 (判断依据是对方没有出现在会话列表中)
    ///
    /// - Parameter chatUnit: 聊天对象
    /// - Returns: 如果是true 则表示没有和对方聊过天
    public func isNeverChat(_ chatUnit: IMChatUnit) -> Bool {
        return conversationManager.isNeverChat(chatUnit)
    }
}

//MARK: - 修改我的个人信息
extension IMChatManager {
    
    /// 修改自己的昵称
    public func modifySelfNickname(_ nick : String) {
        guard nick.count > 0 && nick.count < 64 else { return }
        updateMyUserModel(nickName: nick)
    }
    
    /// 修改自己的头像
    public func modifySelfFacePath(_ path : String) {
        updateMyUserModel(facePath: path)
    }
    
    /// 同步个人资料
    public func updateHostProfile() {
        TIMFriendshipManager.sharedInstance().getSelfProfile({ (profile) in
            
            guard let unwrappedProfile = profile else { return }
            self.host?.model.facePath = unwrappedProfile.faceURL
            self.host?.model.nickName = unwrappedProfile.nickname
            
        }, fail: { (code , str) in
            //同步资料失败
        })
    }
    
    private func updateMyUserModel(facePath: String? = nil, nickName: String? = nil) {
        
        let option = TIMFriendProfileOption()
        let profile = TIMUserProfile()
        
        if let unwrappedFacePath = facePath {
            option.friendFlags = UInt64(TIMProfileFlag.PROFILE_FLAG_FACE_URL.rawValue)  //表示头像
            profile.faceURL = unwrappedFacePath
            self.host?.model.facePath = unwrappedFacePath
        }
        
        if let unwrappedNickName = nickName {
            option.friendFlags = UInt64(TIMProfileFlag.PROFILE_FLAG_NICK.rawValue)  //表示昵称
            profile.nickname = unwrappedNickName
            self.host?.model.facePath = unwrappedNickName
        }
        
        TIMFriendshipManager.sharedInstance().modifySelfProfile(option, profile: profile, succ: {
            
        }) { (code, str) in
            //设置个人信息失败
        }
    }
}
