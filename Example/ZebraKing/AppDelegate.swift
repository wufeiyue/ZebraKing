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

    let mockSource = [ProfileModel(title: "用户的账号类型", identifier: "accountType"),
                      ProfileModel(title: "用户标识接入SDK的应用", identifier: "appid"),
                      ProfileModel(title: "本地账户的", identifier: "sign"),
                      ProfileModel(title: "本地账户的", identifier: "chatId"),
                      ProfileModel(title: "会话对象的", identifier: "otherChatId")]
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        
        // 注册本地通知
        registerLocalNotification()
        
        // 开发者申请key时可以拿到, 是固定值
        let accountType: String = mockSource[0].content
        let appidAt3rd: String = mockSource[1].content
        
        ZebraKing.register(accountType: accountType, appidAt3rd: Int32(appidAt3rd)!) { notification in
            self.onResponseNotification(notification)
        }
        
        return true
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("已经注册通知")
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("注册通知失败")
    }
   
    /// 如果 App 在后台的时候接受到推送的话，这个方法会被调用
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable : Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        
        completionHandler(.newData)
    }

}

extension AppDelegate {
    
    //FIXME: - App切到后台挂起状态时, 此回调不执行
    private func onResponseNotification(_ notification: ChatNotification) {
        
        //消息发送人的资料
        //let sender = notification.receiver
        
        //推送的内容
        let content = notification.content
        
        if case .background = UIApplication.shared.applicationState {
            //处理本地系统推送(只会在后台推送)
            UIApplication.localNotification(title: "推送消息", body: content ?? "您收到一条新消息", userInfo: ["chatNotification": notification])
        } else {
            NotificationCenter.default.post(name: .didRecievedMessage, object: self, userInfo: ["chatNotification": notification])
        }
        
    }
    
}

//MARK: - 本地通知
extension AppDelegate {
    
    // 注册本地通知
    private func registerLocalNotification() {
        let setting = UIUserNotificationSettings(types: [.alert, .sound, .badge], categories: nil)
        UIApplication.shared.registerUserNotificationSettings(setting)
        UIApplication.shared.registerForRemoteNotifications()
    }
    
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        if let chatNotification = notification.userInfo?["chatNotification"] as? ChatNotification {
            
            ZebraKing.chat(notification: chatNotification) { result in
                switch result {
                case .success(let task):
                    let vc = ChattingViewController(task: task)
                    self.present(vc, animated: true, completion: nil)
                case .failure(_):
                    break
                }
            }
        }
    }
    
    private func present(_ viewController: UIViewController, animated: Bool, completion: (() -> Void)?) {
        let nav = UINavigationController(rootViewController: viewController)
        let rootViewController = UIApplication.shared.keyWindow?.rootViewController
        rootViewController?.present(nav, animated: animated, completion: completion)
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
