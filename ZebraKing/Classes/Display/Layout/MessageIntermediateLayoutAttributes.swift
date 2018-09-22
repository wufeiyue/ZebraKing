//
//  MessageIntermediateLayoutAttributes.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/6.
//  布局管理

import Foundation

enum AvatarPosition {
    case leading
    case trailing
}

public struct MessageIntermediateLayoutAttributes {
    
    //头像位置
    var position: AvatarPosition = .leading
    
    //cell的宽度
    var itemWidth: CGFloat = 0
    
    //头像大小
    var avatarSize: CGSize = .zero
    
    var attachmentStyle: AttachmentStyle = AttachmentStyle()
    
    //消息文本
    var messageContainerSize: CGSize = .zero
    
    //消息的外边距
    var messageContainerPadding: UIEdgeInsets = .zero
    
    //消息的内边距
    var messageLabelInsets: UIEdgeInsets = .zero
    
    //语音时长的size
    var durationSize: CGSize = .zero
    
    //语音时长的外边距
    var durationPadding: UIEdgeInsets = .zero
    
    var audioIconSize: CGSize = .zero
    
    lazy var audioIconRect: CGRect = {
        
        guard audioIconSize != .zero else { return .zero }
        
        var origin: CGPoint = .zero
        
        origin.x = (messageContainerSize.width - audioIconSize.width) / 2
        origin.y = (messageContainerSize.height - audioIconSize.height) / 2
        
        return CGRect(origin: origin, size: audioIconSize)
    }()
    
    lazy var durationRect: CGRect = {
        
        guard durationSize != .zero else { return .zero }
        
        var origin: CGPoint = .zero
        
        origin.y = itemHeight - durationPadding.bottom - durationSize.height
        
        switch position {
        case .leading:
            origin.x = avatarSize.width + messageContainerPadding.left + messageContainerSize.width + durationPadding.left
        case .trailing:
            origin.x = itemWidth - avatarSize.width - messageContainerSize.width - messageContainerPadding.right - durationPadding.right - durationSize.width
        }
        
        return CGRect(origin: origin, size: durationSize)
    }()
    
    lazy var avatarRect: CGRect = {
        
        guard avatarSize != .zero else { return .zero }
        
        var origin: CGPoint = .zero
        
        switch position {
        case .leading:
            break
        case .trailing:
            origin.x = itemWidth - avatarSize.width
        }
        
        return CGRect(origin: origin, size: avatarSize)
    }()
    
    lazy var messageContainerRect: CGRect = {
       
        guard messageContainerSize != .zero else { return .zero }
        
        var origin: CGPoint = .zero
        
        origin.y = messageContainerPadding.top
        
        switch position {
        case .leading:
            origin.x = avatarSize.width + messageContainerPadding.left
        case .trailing:
            origin.x = itemWidth - avatarSize.width - messageContainerSize.width - messageContainerPadding.right
        }
        
        return CGRect(origin: origin, size: messageContainerSize)
    }()
    
    lazy var attachmentFrame: CGRect = {
        
        guard messageContainerSize != .zero else { return .zero }
        
        var origin: CGPoint = .zero
        
        origin.y = messageContainerPadding.top
        
        switch position {
        case .leading:
            break
        case .trailing:
            origin.x = itemWidth - avatarSize.width - messageContainerPadding.right - messageContainerSize.width - attachmentStyle.width - durationSize.width - durationPadding.right - durationPadding.left
        }
        
        return CGRect(origin: origin, size: CGSize(width: attachmentStyle.width, height: messageContainerSize.height))
        
    }()
    
    lazy var itemHeight: CGFloat = {
        return (messageContainerRect.maxY + messageContainerPadding.bottom) > avatarRect.maxY ? (messageContainerRect.maxY  + messageContainerPadding.bottom) : avatarRect.maxY
    }()
    
    var messageLabelVerticalInsets: CGFloat {
        return messageLabelInsets.top + messageLabelInsets.bottom
    }
    
    var messageLabelHorizontalInsets: CGFloat {
        return messageLabelInsets.left + messageLabelInsets.right
    }
    
    var messageVerticalPadding: CGFloat {
        return messageContainerPadding.top + messageContainerPadding.bottom
    }
    
    var messageHorizontalPadding: CGFloat {
        return messageContainerPadding.left + messageContainerPadding.right
    }
    
    init() {}
}
