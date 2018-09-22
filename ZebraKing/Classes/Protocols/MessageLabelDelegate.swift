//
//  MessageLabelDelegate.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/7.
//

import Foundation

public protocol MessageLabelDelegate: AnyObject {
    
    //点击地址
    func didSelectAddress(_ addressComponents: [String: String])
    
    //点击时间
    func didSelectDate(_ date: Date)
    
    //点击电话号码
    func didSelectPhoneNumber(_ phoneNumber: String)
    
    //点击URL
    func didSelectURL(_ url: URL)
    
}

public extension MessageLabelDelegate {
    
    func didSelectAddress(_ addressComponents: [String: String]) {}
    
    func didSelectDate(_ date: Date) {}
    
    func didSelectPhoneNumber(_ phoneNumber: String) {}
    
    func didSelectURL(_ url: URL) {}
    
}
