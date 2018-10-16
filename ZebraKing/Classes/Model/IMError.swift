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
    case loadLocalMessageFailure //获取会话消息
    case sendMessageFailure     //消息发送失败
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
        case .loadLocalMessageFailure:
            return "获取会话消息失败"
        case .sendMessageFailure:
            return "消息发送失败"
        }
    }
}
