
//
//  IMChatUserModel.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//
//
import Foundation
import ImSDK

/// 将要会话的会话对象
public struct IMUserModel {
    
    static var server = IMUserModel(userId: "bmkp")
    
    public private(set) var id: String = ""                    //用户id
    public var facePath: String?                  //用户头像
    public var nickName: String = ""              //昵称
    
    /// 是否缺失必要的资料信息
    public var isLoseMustInfo: Bool {
        return facePath == nil
    }

    public init(id: String, facePath: String?, nickName: String) {
        self.id = id
        self.facePath = facePath
        self.nickName = nickName
    }
    
    public init?(userInfo: [AnyHashable: Any]?) {
        
        guard let unwrappedUserInfo = userInfo else { return nil }
        
        if let id = unwrappedUserInfo["id"] as? String {
            self.id = id
        }
        else {
            return nil
        }
        
        if let facePath = unwrappedUserInfo["facePath"] as? String {
            self.facePath = facePath
        }
        
        if let nickName = unwrappedUserInfo["nickName"] as? String {
            self.nickName = nickName
        }
    }
    
    public init(userId: String){
        self.id = userId
    }

}

extension IMUserModel {
    mutating func addPrefix(_ string: String) {
        id = string + id
    }
}
