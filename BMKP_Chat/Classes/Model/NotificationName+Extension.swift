//
//  NotificationName+Extension.swift
//  BMChat_Example
//
//  Created by 武飞跃 on 2017/11/7.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation

extension Notification.Name {
    
    // 客服  发送的通知
    public static let didRecievedServerMessage = Notification.Name(rawValue: "didRecievedServerMessage")
    
    // 司机  发送的通知
    public static let didRecievedDriverMessage = Notification.Name(rawValue: "didRecievedDriverMessage")
    
    // 乘客  发送的通知
    public static let didRecievedPassengerMessage = Notification.Name(rawValue: "didRecievedPassengerMessage")
    
}
