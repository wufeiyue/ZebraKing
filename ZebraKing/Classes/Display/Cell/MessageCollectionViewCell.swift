//
//  MessageCollectionViewCell.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/27.
//

import Foundation

open class MessageCollectionViewCell: UICollectionViewCell {
    
    //头像
    open var avatarView = UIImageView()
    
    open var messageContainerView = MessageContainerView()
    
    /// 附件视图(消息发送状态)
    open var attachmentView: AttachmentView = AttachmentView()
    
    open weak var delegate: MessageCellDelegate?
    
    private var messageType: MessageType!
    
    open func handleTapGesture(_ gesture: UIGestureRecognizer) {
        let touchLocation = gesture.location(in: self)
        
        let isGestureContentView = cellContentView(canHandle: convert(touchLocation, to: messageContainerView))
        
        switch true {
        case messageContainerView.frame.contains(touchLocation) && (isGestureContentView == false):
            delegate?.didTapMessage(in: self, message: messageType)
        case avatarView.frame.contains(touchLocation):
            delegate?.didTapAvatar(in: self, message: messageType)
        case attachmentView.frame.contains(touchLocation):
            delegate?.didTapAttachment(in: self, message: messageType)
        default:
            break
        }
        
        delegate?.didContainer(in: self, message: messageType)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        setupSubViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override func prepareForReuse() {
        super.prepareForReuse()
        attachmentView.reset()
    }
    
    open func setupSubViews() {
        avatarView.backgroundColor = UIColor(red: 242/255.0, green: 242/255.0, blue: 242/255.0, alpha: 1.0)
        [avatarView, messageContainerView, attachmentView].forEach({ contentView.addSubview($0) })
    }
    
    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attr = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
            messageContainerView.frame = attr.messageContainerFrame
            avatarView.frame = attr.avatarFrame
            attachmentView.frame = attr.attachmentFrame
            attachmentView.layout.messageRect = attr.messageStatusRect
            attachmentView.layout.readRect = attr.readRect
        }
    }
    
    open func configure(with message: MessageType, at indexPath: IndexPath, and messageCollectionView: MessagesCollectionView) {
        
        defer {
            messageType = message
            delegate = messageCollectionView.messageCellDelegate
        }
        
        guard let messageDataSource = messageCollectionView.messageDataSource,
            let displayDelegate = messageCollectionView.messagesDisplayDelegate else {
                fatalError("messageDataSource or messagesDisplayDelegate or messagesLayoutDelegate没有实现")
        }
        
        //判断是否为我发送的消息
        if messageDataSource.isFromCurrentSender(message: message) {
            //替换为蓝色背景
            messageContainerView.image = MessageStyle.text_area_blue.image
            
            //将附件显示出来
            attachmentView.isHidden = false
            attachmentView.style = displayDelegate.attachmentStyle(at: indexPath, message: message, in: messageCollectionView)
            attachmentView.displayView(with: message.status)
        }
        else {
            //替换为白色背景
            messageContainerView.image = MessageStyle.text_area_white.image
            
            //隐藏附件
            attachmentView.isHidden = true
        }
        
        //FIXME: - 缓存的图片要及时清除
        avatarView.kf.setImage(with: message.sender.avatarURL, placeholder: message.sender.placeholder, options: nil, progressBlock: nil, completionHandler: nil)
    }
    
    
    //当contentView不需要处理点击的时候返回false
    open func cellContentView(canHandle touchPoint: CGPoint) -> Bool {
        return false
    }
}
