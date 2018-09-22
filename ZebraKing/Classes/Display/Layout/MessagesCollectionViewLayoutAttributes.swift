//
//  MessagesCollectionViewLayoutAttributes.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/27.
//

import Foundation

final class MessagesCollectionViewLayoutAttributes: UICollectionViewLayoutAttributes {
    
    //头像的frame
    var avatarFrame: CGRect = .zero
    
    //消息容器视图rect
    var messageContainerFrame: CGRect = .zero
    
    //消息文本大小
    var messageLabelFont: UIFont = UIFont.preferredFont(forTextStyle: .body)
    
    //消息文本的内边距
    var messageLabelInsets: UIEdgeInsets = .zero
    
    //附件的尺寸
    var attachmentFrame: CGRect = .zero
    
    //已读未读
    var readRect: CGRect = .zero
    
    //消息发送的状态
    var messageStatusRect: CGRect = .zero
    
    //语音时长
    var durationRect: CGRect = .zero
    
    //语音消息图标
    var audioIconRect: CGRect = .zero
    
    override func copy(with zone: NSZone? = nil) -> Any {
        
        let copy = super.copy(with: zone) as! MessagesCollectionViewLayoutAttributes
        copy.avatarFrame = avatarFrame
        copy.messageContainerFrame = messageContainerFrame
        copy.messageLabelInsets = messageLabelInsets
        copy.messageLabelFont = messageLabelFont
        copy.attachmentFrame = attachmentFrame
        copy.readRect = readRect
        copy.messageStatusRect = messageStatusRect
        copy.durationRect = durationRect
        copy.audioIconRect = audioIconRect
        return copy
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let _ = object as? MessagesCollectionViewLayoutAttributes {
            return super.isEqual(object)
        }
        return false
    }
}
