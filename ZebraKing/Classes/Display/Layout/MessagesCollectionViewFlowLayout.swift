//
//  MessagesCollectionViewFlowLayout.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/27.
//

import Foundation

open class MessagesCollectionViewFlowLayout: UICollectionViewFlowLayout {
    
    //最大可缓存的cell布局的数量
    open var attributesCacheMaxSize: Int = 500
    
    fileprivate var intermediateAttributesCache: [MessageID: MessageIntermediateLayoutAttributes] = [:]
    
    fileprivate var messageDataSource: MessagesDataSource {
        guard let dataSource = messagesCollectionView.messageDataSource else { fatalError("messageDataSource没有实现") }
        return dataSource
    }
    
    fileprivate var messagesLayoutDelegate: MessagesLayoutDelegate {
        guard let layoutDelegate = messagesCollectionView.messagesLayoutDelegate else { fatalError("messagesLayoutDelegate没有实现") }
        return layoutDelegate
    }
    
    fileprivate var messagesCollectionView: MessagesCollectionView {
        guard let collectionView = collectionView as? MessagesCollectionView else { fatalError("强转CollectionView失败") }
        return collectionView
    }
    
    fileprivate var itemWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        return collectionView.bounds.size.width - sectionInset.left - sectionInset.right
    }
    
    fileprivate var messageLabelFont: UIFont!
    
    public override init() {
        
        //        emojiLabelFont = messageLabelFont.withSize(2 * messageLabelFont.pointSize)
        //
        super.init()
        messageLabelFont = UIFont.systemFont(ofSize: 16)
        
        sectionInset = UIEdgeInsets(top: 4, left: 10, bottom: 4, right: 10)
        //
        //        NotificationCenter.default.addObserver(self, selector: #selector(MessagesCollectionViewFlowLayout.handleOrientationChange(_:)), name: .UIDeviceOrientationDidChange, object: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func sizeForItem(at indexPath: IndexPath) -> CGSize {
        var attributes = messageIntermediateLayoutAttributes(for: indexPath)
        return CGSize(width: itemWidth, height: attributes.itemHeight)
    }
    
    public func removeAllCachedAttributes() {
        intermediateAttributesCache.removeAll()
    }
    
}

extension MessagesCollectionViewFlowLayout {
    func messageIntermediateLayoutAttributes(for indexPath: IndexPath) -> MessageIntermediateLayoutAttributes {
        
        let message = messageDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        
        if let intermediateAttributes = intermediateAttributesCache[message.messageId] {
            return intermediateAttributes
        }
        else {
            let newAttributes = createMessageIntermediateLayoutAttributes(indexPath: indexPath, message: message)
            
            //默认不超过字典最大限制, 就可以缓存布局
            let shouldCache = intermediateAttributesCache.count < attributesCacheMaxSize
            
            if shouldCache {
                intermediateAttributesCache[message.messageId] = newAttributes
            }
            
            return newAttributes
        }
        
    }
    
    private func createMessageIntermediateLayoutAttributes(indexPath: IndexPath, message: MessageType) -> MessageIntermediateLayoutAttributes {
        
        let size = messagesLayoutDelegate.avatarSize(at: indexPath, in: messagesCollectionView)
        
        let padding = messagesLayoutDelegate.messagePadding(at: indexPath, in: messagesCollectionView)
        
        let insets = messagesLayoutDelegate.messageInsets(at: indexPath, message: message, in: messagesCollectionView)
        
        let attachmentStyle = messagesLayoutDelegate.attachmentStyle(at: indexPath, message: message, in: messagesCollectionView)
        
        let durationSize = messagesLayoutDelegate.durationSize(at: indexPath, message: message, in: messagesCollectionView)
        
        let durationEdge = messagesLayoutDelegate.durationInsets(at: indexPath, message: message, in: messagesCollectionView)
        
        let audioIconSize = messagesLayoutDelegate.audioIconSize(at: indexPath, in: messagesCollectionView)
        
        var attributes = MessageIntermediateLayoutAttributes()
        
        let postion = avatarPosition(for: attributes, indexPath: indexPath)
        
        attributes.audioIconSize = audioIconSize
        
        attributes.position = postion
        
        attributes.avatarSize = size
        
        attributes.itemWidth = itemWidth
        
        attributes.messageContainerPadding = padding
        
        attributes.messageLabelInsets = insets
        
        attributes.messageContainerSize = messageContainerSize(for: attributes, message: message)
        
        attributes.durationSize = durationSize
        
        attributes.durationPadding = durationEdge
        
        attributes.attachmentStyle = attachmentStyle
        
        return attributes
    }
}

private extension MessagesCollectionViewFlowLayout {
    
    //计算消息的大小
    func messageContainerSize(for attributes: MessageIntermediateLayoutAttributes, message: MessageType) -> CGSize {
        
        let maxWidth = messageContainerMaxWidth(for: attributes, message: message)
        
        var messageContainerSize: CGSize = .zero
        
        switch message.data {
        case .text(let text):
            messageContainerSize = labelSize(for: text, considering: maxWidth, font: messageLabelFont)
            messageContainerSize.width += attributes.messageLabelHorizontalInsets
            messageContainerSize.height += attributes.messageLabelVerticalInsets
        case .audio(_ , let second):
            //FIXME: - 固定值
            let voicelength = 70 + 130 * (CGFloat(second)/60)
            messageContainerSize = CGSize.init(width: min(voicelength, 200), height: 40)
        default:
            break
        }
        
        return messageContainerSize
    }
    
    func messageContainerMaxWidth(for attributes: MessageIntermediateLayoutAttributes, message: MessageType) -> CGFloat {
        
        switch message.data {
        case .text, .attributedText:
            return itemWidth - (2 * attributes.avatarSize.width) - attributes.messageHorizontalPadding - attributes.messageLabelHorizontalInsets
        default:
            return itemWidth - attributes.avatarSize.width - (attributes.messageContainerPadding.left + attributes.messageContainerPadding.right)
        }
        
    }
    
    func avatarPosition(for attributes: MessageIntermediateLayoutAttributes, indexPath: IndexPath) -> AvatarPosition {
        
        let message = messageDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
        
        let isFromCurrentSender = messageDataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? .trailing : .leading
    }
    
    func labelSize(for attr: NSAttributedString, considering maxWidth: CGFloat) -> CGSize {
        
        let estimatedHeight = attr.height(considering: maxWidth)
        let estimatedWidth = attr.width(considering: estimatedHeight)
        
        let finalHeight = estimatedHeight.rounded(.up)
        let finalWidth = estimatedWidth > maxWidth ? maxWidth : estimatedWidth.rounded(.up)
        
        return CGSize(width: finalWidth, height: finalHeight)
    }
    
    func labelSize(for text: String, considering maxWidth: CGFloat, font: UIFont) -> CGSize {
        
        let estimatedHeight = text.height(considering: maxWidth, and: font)
        let estimatedWidth = text.width(considering: estimatedHeight, and: font)
        
        let finalHeight = estimatedHeight.rounded(.up)
        let finalWidth = estimatedWidth > maxWidth ? maxWidth : estimatedWidth.rounded(.up)
        
        return CGSize(width: finalWidth, height: finalHeight)
    }
    
}

extension MessagesCollectionViewFlowLayout {
    //重写父类方法，提供一个通用类以来初始化MessagesCollectionViewLayoutAttributes的实例, 此类必须继承自UICollectionViewLayoutAttributes
    open override class var layoutAttributesClass: AnyClass {
        return MessagesCollectionViewLayoutAttributes.self
    }
    
    open override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        
        guard let attributesList = super.layoutAttributesForElements(in: rect) as? [MessagesCollectionViewLayoutAttributes] else { return nil }
        
        attributesList.forEach { attr in
            if attr.representedElementCategory == UICollectionElementCategory.cell {
                confiure(attributes: attr)
            }
        }
        
        return attributesList
    }
    
    open override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        
        guard let attributes = super.layoutAttributesForItem(at: indexPath) as? MessagesCollectionViewLayoutAttributes else { return nil }
        
        if attributes.representedElementCategory == UICollectionElementCategory.cell {
            confiure(attributes: attributes)
        }
        
        return attributes
    }
    
    private func confiure(attributes: MessagesCollectionViewLayoutAttributes) {
        
        var intermediateAttributes = messageIntermediateLayoutAttributes(for: attributes.indexPath)
        
        attributes.avatarFrame = intermediateAttributes.avatarRect
        attributes.messageLabelInsets = intermediateAttributes.messageLabelInsets
        attributes.messageContainerFrame = intermediateAttributes.messageContainerRect
        attributes.messageLabelFont = messageLabelFont
        attributes.attachmentFrame = intermediateAttributes.attachmentFrame
        attributes.messageStatusRect = intermediateAttributes.attachmentStyle.messageRect
        attributes.readRect = intermediateAttributes.attachmentStyle.readRect
        attributes.durationRect = intermediateAttributes.durationRect
        attributes.audioIconRect = intermediateAttributes.audioIconRect
    }
}
