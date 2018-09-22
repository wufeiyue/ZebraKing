//
//  TextMessageCell.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/27.
//

import Foundation

open class TextMessageCell: MessageCollectionViewCell {
    
    open var messageLabel = MessageLabel()
    
    open override var delegate: MessageCellDelegate? {
        didSet {
            messageLabel.delegate = delegate
        }
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.text = nil
        messageLabel.attributedText = nil
    }
    
    open override func setupSubViews() {
        super.setupSubViews()
        messageContainerView.addSubview(messageLabel)
    }
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messageCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messageCollectionView)
        
        guard let layoutDelegate = messageCollectionView.messagesDisplayDelegate else { fatalError("messagesDisplayDelegate没有实现") }
        let textColor = layoutDelegate.textColor(for: message, at: indexPath, in: messageCollectionView)
        
        messageLabel.configure {
            
            switch message.data {
            case .text(let text):
                messageLabel.text = text
            case .attributedText(let text):
                messageLabel.attributedText = text
            default:
                break
            }
            
            messageLabel.textColor = textColor
        }
    }
    
    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
            messageLabel.textInsets = attributes.messageLabelInsets
            messageLabel.font = attributes.messageLabelFont
            messageLabel.frame = messageContainerView.bounds
        }
    }
    
}
