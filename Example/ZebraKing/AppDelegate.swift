//
//  AppDelegate.swift
//  ZebraKing
//
//  Created by eppeo on 09/22/2018.
//  Copyright (c) 2018 eppeo. All rights reserved.
//

import UIKit
import ZebraKing
import UserNotifications

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        
        // 开发者申请key时可以拿到, 是固定值
        let accountType: String = mockSource[0].content
        let appidAt3rd: String = mockSource[1].content
        let host = UIImage(named: "chat_header-passenter")
        let receiver = UIImage(named: "chat_header-driver")
        
        let config = ZebraKingUserConfig(accountType: accountType,
                                         appidAt3rd: appidAt3rd,
                                         hostAvatar: host,
                                         receiverAvatar: receiver)
        
        ZebraKing.register(config: config, delegate: self)
        
        //注册推送
//        registerNotification()
        
        return true
    }

    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable:Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        if let chatNotification = userInfo["chatNotification"] as? ChatNotification {
            
            ZebraKing.chat(notification: chatNotification) { result in
                switch result {
                case .success(let conversation):
                    let chattingViewController = ChattingViewController(conversation: conversation)
                    let nav = UINavigationController(rootViewController: chattingViewController)
                    self.present(nav, animated: true, completion: nil)
                case .failure(_):
                    break
                }
            }
        }
        
        completionHandler(.newData)
    }
    
    func registerNotification() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { (isCompleted, error) in
            }
            
        } else {
            //注册推送
            let settings = UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
            UIApplication.shared.registerUserNotificationSettings(settings)
            
        }
    }
    
    func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        rootViewController?.present(viewController, animated: animated, completion: completion)
    }
    
    let mockSource = [ProfileModel(title: "用户的账号类型  (String) ", identifier: "accountType"), ProfileModel(title: "用户标识接入SDK的应用ID (Int32) ", identifier: "appid"), ProfileModel(title: "本地账户的sign (String) ", identifier: "sign"), ProfileModel(title: "本地账户的chatId (String) ", identifier: "chatId"), ProfileModel(title: "对方账户的chatId (String) ", identifier: "otherChatId")]
}

extension AppDelegate: ZebraKingDelegate {
    
    func onResponseNotification(_ notification: ChatNotification) {
        
        //消息发送人的资料
        //let sender = notification.receiver
        
        //是否处于会话活跃窗口(一般处于会话窗口就不让在前台推送了)
        let isChatting = notification.isChatting
        
        //推送的内容
        let content = notification.content
        
        if case .background = UIApplication.shared.applicationState {
            //处理本地系统推送(只会在后台推送)
            UIApplication.localNotification(title: "推送消息", body: content ?? "您收到一条新消息", userInfo: ["chatNotification": notification])
            print("处于后台")
        } else if !isChatting {
            NotificationCenter.default.post(name: .didRecievedMessage, object: self, userInfo: ["chatNotification": notification])
        }
        
    }
    
}

extension Notification.Name {
    
    // 发送的通知
    public static let didRecievedMessage = Notification.Name(rawValue: "didRecievedMessage")
}

extension UIApplication {
    
    /// 触发本地通知
    ///
    /// - Parameters:
    ///   - title: 标题
    ///   - body: 内容
    ///   - userInfo: 自定义信息
    public static func localNotification(title: String, body: String, dateComponents: DateComponents? = nil, userInfo : [AnyHashable : Any]? = nil) {
        if #available(iOS 10, *) {
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            content.userInfo = userInfo ?? [:]
            
            var trigger: UNNotificationTrigger?
            if let dataCompontnts = dateComponents {
                trigger = UNCalendarNotificationTrigger(dateMatching: dataCompontnts, repeats: false)
            }
            
            let request = UNNotificationRequest(identifier: "bm_id", content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: { error in
                print(error ?? "推送未知错误")
            })
            
        } else {
            let localNotification = UILocalNotification()
            localNotification.fireDate = dateComponents?.date ?? Date()
            localNotification.alertBody = body
            localNotification.alertTitle = title
            localNotification.userInfo = userInfo
            localNotification.timeZone = NSTimeZone.default
            localNotification.soundName = UILocalNotificationDefaultSoundName
            UIApplication.shared.scheduleLocalNotification(localNotification)
        }
    }
}
