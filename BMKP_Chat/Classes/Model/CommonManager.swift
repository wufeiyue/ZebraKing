//
//  CommonManager.swift
//  BMChat_Example
//
//  Created by 武飞跃 on 2017/11/1.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation
import ImSDK
import IMMessageExt
/*
 本地管理常用语,卸载App就重置
 
 取值
 赋值全依赖于 操作 dataSource
 
 初始化数据需调用prepare() 便于在不同账户之间切换时,调用更新数据
 
 */
public struct CommonManager {
    
    //常用语
    var dataSource: Array<String> {
        set {
            
            if _dataSource == nil {
                _dataSource = newValue
                save()
            }
            else if _dataSource?.elementsEqual(newValue) == false{
                _dataSource = newValue
                save()
            }
            
        }
        
        get {
            if let unwrapped = _dataSource{
                return unwrapped
            }
            switch type {
            case .passenger:
                return ["您好，我们可以准时出发吗",
                        "预计一分钟内到达您的上车地点",
                        "你好，可以快点吗，车上还有其他乘客",
                        "请稍等，我马上就到"]
            case .driver:
                return ["请稍等，我马上就到",
                        "您好，我们准时出发吗",
                        "我的定位很准,可以直接按导航来接我",
                        "您好，可以快点吗? 等的时间有点久了哦"]
            case .server:
                return []
            }
        }
    }
    
    private var _dataSource: Array<String>?
    private var currentLoginUser: String?
    private var key: String = ""
    public var type: IMChatRole = .driver
    mutating public func prepare() {
        if let unwrappedLoginId = TIMManager.sharedInstance().getLoginUser(), unwrappedLoginId != currentLoginUser {
            currentLoginUser = unwrappedLoginId
            key = "bmkp_im_common_messages" + unwrappedLoginId
            self.reset()
            self.fetch()
        }
    }
    
    //保存数据到本地
    private func save() {
        guard let list = _dataSource?.map({ return $0 + "👉" }) else {
            return
        }
        let combination = list.reduce("") { (result, elem) -> String in
            return result + elem
        }
        if key.isEmpty == false {
            UserDefaults.standard.set(combination, forKey: key)
            UserDefaults.standard.synchronize()
        }
    }
    
    //取本地数据
    private mutating func fetch() {
        if let combination = UserDefaults.standard.string(forKey: key) {
            _dataSource = combination.components(separatedBy: "👉").filter({ $0.isEmpty == false })
        }
    }
    
    //重置
    private mutating func reset() {
        _dataSource?.removeAll()
        _dataSource = nil
    }

}
