//
//  IMChatUnit.swift
//  BMChat_Example
//
//  Created by 武飞跃 on 2017/11/9.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation

public struct IMChatUnit {
    
    public static let server = IMChatUnit(role: .server, id: "bmkp")!
    
    public let role: IMChatRole
    public let id: String
    
    public init?(role: IMChatRole? = nil, id: String) {
        
        if let unwrappedRole = role {
            if IMChatRole.convert(id) == nil {
                self.id = unwrappedRole.prefix + id
            }
            else {
                self.id = id
            }
            self.role = unwrappedRole
        }
        else {
            if let role = IMChatRole.convert(id){
                self.role = role
                self.id = id
            }
            else {
                return nil
            }
        }
        
    }
}

extension IMChatUnit: Hashable {
    
    public static func ==(lhs: IMChatUnit, rhs: IMChatUnit) -> Bool {
        return lhs.id == rhs.id
    }
    
    public var hashValue: Int {
        return id.hashValue
    }
}
