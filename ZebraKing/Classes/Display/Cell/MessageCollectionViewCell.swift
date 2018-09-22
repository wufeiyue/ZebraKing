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
        
        switch true {
        case messageContainerView.frame.contains(touchLocation):
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
        attachmentView.text = nil
    }
    
    open func setupSubViews() {
        avatarView.backgroundColor = .lightGray
        [avatarView, messageContainerView, attachmentView].forEach({ contentView.addSubview($0) })
    }
    
    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attr = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
            messageContainerView.frame = attr.messageContainerFrame
            avatarView.frame = attr.avatarFrame
            attachmentView.frame = attr.attachmentFrame
            attachmentView.messageRect = attr.messageStatusRect
            attachmentView.readRect = attr.readRect
        }
    }
    
    open func configure(with message: MessageType, at indexPath: IndexPath, and messageCollectionView: MessagesCollectionView) {
        
        defer {
            messageType = message
        }
        
        guard let messageDataSource = messageCollectionView.messageDataSource, let layoutDelegate = messageCollectionView.messagesDisplayDelegate else { fatalError("messageDataSource没有实现") }
        
        //判断是否为我发送的消息
        if messageDataSource.isFromCurrentSender(message: message) {
            //替换为蓝色背景
            messageContainerView.image = MessageStyle.text_area_blue.image()
            //将附件显示出来
            attachmentView.isHidden = false
            
            let readStatus = layoutDelegate.readStatus(for: message, at: indexPath, in: messageCollectionView)
            
            if readStatus {
                let textColor = layoutDelegate.readTextColor(for: message, at: indexPath, in: messageCollectionView)
                let font = layoutDelegate.readTextFont(for: message, at: indexPath, in: messageCollectionView)
                
                attachmentView.readStatusLab.textColor = textColor
                attachmentView.readStatusLab.font = font
                attachmentView.text = message.isRead ? "已读" : "未读"
                
            }
        }
        else {
            //替换为白色背景
            messageContainerView.image = MessageStyle.text_area_white.image()
            //隐藏附件
            attachmentView.isHidden = true
        }
        
        //FIXME: - 缓存的图片要及时清除
        avatarView.kf.setImage(with: message.sender.avatarURL, placeholder: message.sender.placeholder, options: nil, progressBlock: nil, completionHandler: nil)
        displayView(with: message.status)
        delegate = messageCollectionView.messageCellDelegate
    }
    
    open func displayView(with messageStatus: MessageStatus) {
        switch messageStatus {
        case .sending:
            if attachmentView.isHidden == false {
                attachmentView.readStatusLab.isHidden = true
            }
        case .success:
            if attachmentView.isHidden == false {
                attachmentView.readStatusLab.isHidden = false
            }
        default:
            break
        }
    }
}
