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
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType]
    
//    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any]
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey: Any]
    func attachmentStyle(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> AttachmentStyle
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
    
    public func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return []
    }
    
    public func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedStringKey: Any] {
        return MessageLabel.defaultAttributes
    }
    
    public func attachmentStyle(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> AttachmentStyle {
        
        var style = AttachmentStyle()
        if message.isRead {
            style.textColor = UIColor(red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1)
            style.text = "已读"
        }
        else {
            style.textColor = .orange
            style.text = "未读"
        }
        return style
    }
}
