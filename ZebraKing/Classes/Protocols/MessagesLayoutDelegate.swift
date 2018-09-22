//
//  MessagesLayoutDelegate.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/7.
//

import Foundation

public protocol MessagesLayoutDelegate: AnyObject {
    
    //消息的外边距
    func messagePadding(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets
    
    //头像的size
    func avatarSize(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize
    
    //消息的外边距
    func messageInsets(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets
    
    //附件的size
    func attachmentStyle(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> AttachmentStyle
    
    func audioIconSize(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize
    
    func durationSize(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> CGSize
    
    func durationInsets(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets
}

extension MessagesLayoutDelegate {
    public func messageInsets(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        return UIEdgeInsets(top: 6, left: 6, bottom: 6, right: 6)
    }
    
    public func audioIconSize(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 16, height: 18)
    }
    
    public func attachmentStyle(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> AttachmentStyle {
        var style = AttachmentStyle()
        if case .audio(_,_) = message.data {
            style.readRect = CGRect(x: 0, y: 0, width: 30, height: 16)
        }
        return style
    }
    
    public func durationSize(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        if case .audio(_, let second) = message.data {
            if second >= 10 {
                return CGSize(width: 24, height: 15)
            }
            else {
                return CGSize(width: 15, height: 15)
            }
        }
        return .zero
    }
    
    public func durationInsets(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        if case .audio(_, _) = message.data {
            return UIEdgeInsets(top: 0, left: 5, bottom: 5, right: 5)
        }
        return .zero
    }
}

public struct AttachmentStyle {
    
    //MARK: - 设置已读未读
    
    /* 设置已读未读距离消息框(messageContainerView)的距离, 以右下角为坐标(0,0), 向左向上取正值
     
                    ^ +
                    |4
                    |3
     <--------------|2 消息框
     6   5  4  3  2 1
     
     */
    public var readRect: CGRect = CGRect(x: 5, y: 0, width: 30, height: 16)
    
    public var messageRect: CGRect = CGRect(x: 5, y: 0, width: 20, height: 20)
    
    /// 自身的宽度
    public var width: CGFloat = 36
    
}
