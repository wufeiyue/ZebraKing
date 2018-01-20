//
//  IMUserUnit.swift
//  BMChat_Example
//
//  Created by 武飞跃 on 2017/11/7.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation

public struct IMUserUnit {
    
    public static let server = IMUserUnit(role: .server, model: .server)!
    
    public let role: IMChatRole
    public var model: IMUserModel
    
    public init?(role: IMChatRole? = nil, model: IMUserModel) {
        
        var tempModel = model
        
        if let unwrappedRole = role {
            if IMChatRole.convert(model.id) == nil {
                tempModel.addPrefix(unwrappedRole.prefix)
            }
            self.role = unwrappedRole
        }
        else {
            if let role = IMChatRole.convert(model.id){
                self.role = role
            }
            else {
                return nil
            }
        }
        
        self.model = tempModel
        
    }
    
    public var chatModel: IMChatUnit {
        return IMChatUnit(role: role, id: model.id)!
    }
    
    public var name: String {
        return role.simpleName(with: model.nickName)
    }
    
}

