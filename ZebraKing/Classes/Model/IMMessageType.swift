//
//  IMMessageType.swift
//  BMChat
//
//  Created by 武飞跃 on 2017/10/27.
//  Copyright © 2017年 武飞跃. All rights reserved.
//

import Foundation
import ImSDK
import IMMessageExt

/**
 消息类型
 */
public enum IMMessageType: Int {
    case unknown            // 未知消息类型
    case text               // 文本
    case image              // 图片
    case file               // 文件
    case sound              // 语音
    case face               // 表情
    case location           // 定位
    case video              // 视频消息
    case custom             // 自定义
    case timeTip            // 时间提醒标签，不存在于IMSDK缓存的数据库中，业务动态生成
    case inputStatus        // 对方输入状态
    case saftyTip           // 敏感词消息提醒标签，不存在缓存中，退出聊天界面再进入，则不存在了
    case multi              // 富文消息，后期所有聊天消息全部使用富文本显示
    case snsSystem          // 关系链消息
    case profileSystem      // 资料变更消息
    
    static func convert(from msg: TIMMessage) -> IMMessageType {
        
        guard msg.elemCount() != 0 else { return .unknown }
        
        if msg.elemCount() > 1 {
            return .multi
        }else {
            let ele: TIMElem = msg.getElem(0)
            switch ele {
            case is TIMTextElem:            return .text
            case is TIMImageElem:           return .image
            case is TIMFileElem:            return .file
            case is TIMFaceElem:            return .face
            case is TIMLocationElem:        return .location
            case is TIMSoundElem:           return .sound
            case is TIMVideoElem:           return .video
            case is TIMCustomElem:          return .custom
            case is TIMProfileSystemElem:   return .profileSystem
            case is TIMSNSSystemElem:       return .snsSystem
            default:                        return .unknown
            }
        }
        
    }
}


