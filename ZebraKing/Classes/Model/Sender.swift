//
//  Sender.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/6.
//

import Foundation

public struct Sender {
    
    //唯一标示
    public let id: String
    
    //昵称
    public var displayName: String = ""
    
    //头像路径path
    public var facePath: String?
    
    //默认头像
    public var placeholder: UIImage? = MessageStyle.avatar.image
    
    public init(id: String) {
        self.id = id
    }
    
    public init(id: String, displayName: String) {
        self.id = id
        self.displayName = displayName
    }
}

extension Sender {
    
    //是否缺失必要的文件
    public var isLossNecessary: Bool {
        return avatarURL == nil && placeholder == nil
    }
    
    //头像url
    public var avatarURL: URL? {
        guard let path = facePath else {
            return nil
        }
        return URL(string: path)
    }
}

extension Sender: Equatable {
    public static func ==(lhs: Sender, rhs: Sender) -> Bool {
        return lhs.id == rhs.id
    }
}
