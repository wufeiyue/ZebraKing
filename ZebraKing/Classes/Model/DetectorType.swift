//
//  DetectorType.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/7.
//

import Foundation

public enum DetectorType {
    
    case address
    case date
    case phoneNumber
    case url
    
    var textCheckingType: NSTextCheckingResult.CheckingType {
        switch self {
        case .address: return .address
        case .date: return .date
        case .phoneNumber: return .phoneNumber
        case .url: return .link
        }
    }
    
}
