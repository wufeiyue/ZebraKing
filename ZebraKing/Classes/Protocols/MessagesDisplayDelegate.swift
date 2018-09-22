//
//  MessagesDisplayDelegate.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/7.
//

import Foundation

public protocol MessagesDisplayDelegate: AnyObject {
    /// 消息框里的文本颜色
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor
    
    /// 是否显示已读未读提示文本
    func readStatus(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool
    
    /// 配置已读未读文本的颜色
    func readTextColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor
    
    /// 配置已读未读文本的font
    func readTextFont(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIFont
}

extension MessagesDisplayDelegate {
    
    public func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        guard let dataSource = messagesCollectionView.messageDataSource else { fatalError("messageDataSource没有实现") }
        if dataSource.isFromCurrentSender(message: message) {
            return .white
        }
        else {
            return .black
        }
    }
    
    public func readStatus(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
        return false
    }
    
    public func readTextColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        if message.isRead {
            return UIColor(red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1)
        }
        else {
            return .orange
        }
    }
    
    public func readTextFont(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIFont {
        return .systemFont(ofSize: 12)
    }
}
