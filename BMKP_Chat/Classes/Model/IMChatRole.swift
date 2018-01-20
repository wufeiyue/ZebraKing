//
//  IMChatRole.swift
//  BMChat_Example
//
//  Created by 武飞跃 on 2017/11/2.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation

public enum IMChatRole {
    case driver     //司机
    case passenger  //乘客
    case server     //客服
    
    public static func convert(_ userId: String) -> IMChatRole? {
        if userId.hasPrefix("D") {
            return .driver
        }
        else if userId.hasPrefix("C"){
            return .passenger
        }
        else if userId == "bmkp" {
            return .server
        }
        
        return nil
    }
    
    public var prefix: String {
        switch self {
        case .driver:
            return "D"
        case .passenger:
            return "C"
        default:
            return ""
        }
    }
    
}

extension IMChatRole {
    
    /// 转换昵称
    ///
    /// - Parameter realName: 真实姓名
    /// - Returns: 简称
    public func simpleName(with realName: String) -> String {
        switch self {
        case .driver:
            return realName.interceptStringByIM()
        case .passenger:
            return realName
        case .server:
            return "在线客服"
        }
    }
    
    public var imageName: String {
        switch self {
        case .driver:
            return "chat_header-driver"
        case .passenger:
            return "chat_header-passenter"
        case .server:
            return "chat_header-zebra"
        }
    }
}

extension IMChatRole {
    //转换成ActionBar类型
    public var actionBarType: IMChatActionBarType {
        switch self {
        case .driver, .passenger:
            return .normal
        default:
            return .onlyText("请输入您遇到的问题~")
        }
    }
}

extension String {
    
    public func interceptStringByIM() -> String {
        if self.count > 0 {
            let toindex = index(startIndex, offsetBy: 1)
            return String.init(self[..<toindex] + "师傅")
        }
        return "司机师傅"
    }
    
}
