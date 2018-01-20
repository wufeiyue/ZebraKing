//
//  IMMessageStatus.swift
//  BMChat
//
//  Created by 武飞跃 on 2017/10/27.
//  Copyright © 2017年 bmkp. All rights reserved.
//

import Foundation
import ImSDK
import IMMessageExt

/**
 消息状态
 */
public enum IMMessageStatus: Int {
    case create = -1        // 初始化, 为兼容TIMMessageStatus，从－1开始，创建的消息
    case willSending = 0    // 即将发送,加入到IMAConversation的_msgList，但未发送，如发送语音，可以用于先在界面上显示
    case sending = 1        // 消息发送中
    case sendSucc = 2       // 消息发送成功
    case sendFail = 3       // 消息发送失败
    case safity = 4         // 敏感词汇信息状态
    
    public static func convert(from type:TIMMessageStatus) -> IMMessageStatus {
        switch type {
        case .MSG_STATUS_SEND_SUCC:
            return .sendSucc
        case .MSG_STATUS_SEND_FAIL:
            return .sendFail
        case .MSG_STATUS_SENDING:
            return .sending
        default:
            return .create
        }
    }
}

