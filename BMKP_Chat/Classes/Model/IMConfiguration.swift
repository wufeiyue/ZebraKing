//
//  IMConfiguration.swift
//  BMChat
//
//  Created by 武飞跃 on 2017/10/27.
//  Copyright © 2017年 BMChat. All rights reserved.
// 配置

import Foundation
import ImSDK

public class IMConfiguation: TIMLoginParam {
    
    public var accountType:String                  //用户的账号类型
    public var disableLog:Bool = false             //禁止在控制台打印
    public var environment: Int32 = 0              //默认正式环境
    public var logLevel: TIMLogLevel = .LOG_DEBUG  //日志级别手动设置为none
    public init(accountType:String, appid:String) {
        self.accountType = accountType
        super.init()
        self.appidAt3rd = appid
    }
    
}


