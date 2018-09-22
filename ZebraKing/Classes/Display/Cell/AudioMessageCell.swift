//
//  AudioMessageCell.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/27.
//

import Foundation

open class AudioMessageCell: MessageCollectionViewCell {
    
    public var listenVoiceView: UIImageView = {
        let btn = UIImageView()
        btn.animationDuration = 1
        btn.backgroundColor = .clear
        btn.contentMode = .scaleAspectFit
        return btn
    }()
    
    public var durationLab: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.textColor = UIColor(red: 128.0/255, green: 128.0/255, blue: 128.0/255, alpha: 1)
        return label
    }()
    
    public private(set) var isMineMsg: Bool = false
    
    open override func setupSubViews() {
        super.setupSubViews()
        messageContainerView.addSubview(listenVoiceView)
        contentView.addSubview(durationLab)
    }
    
    public func normalAudio() {
        resetVoiceButton()
    }
    
    public func selectedAudio() {
        startPlayVoiceBtnChange()
    }
    
    private func resetVoiceButton(){
        if isMineMsg {
            listenVoiceView.image = MessageStyle.soundwave_w_n.image()
        }else{
            listenVoiceView.image = MessageStyle.soundwave_b_n.image()
        }
    }
    
    private func startPlayVoiceBtnChange(){
        if isMineMsg {
            listenVoiceView.kf.setImage(with: MessageStyle.soundwave_w_s.fileURL())
        }else{
            listenVoiceView.kf.setImage(with: MessageStyle.soundwave_b_s.fileURL())
        }
    }
    
    open override func configure(with message: MessageType, at indexPath: IndexPath, and messageCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messageCollectionView)
        
        guard let messageDataSource = messageCollectionView.messageDataSource else { fatalError("messageDataSource没有实现") }
        if messageDataSource.isFromCurrentSender(message: message) {
            isMineMsg = true
        }
        else {
            isMineMsg = false
        }
        
        if case .audio(_, let second) = message.data {
            durationLab.text = "\(second)\""
        }
        
        resetVoiceButton()
    }
    
    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
            durationLab.frame = attributes.durationRect
            listenVoiceView.frame = attributes.audioIconRect
        }
    }
    
    open override func displayView(with messageStatus: MessageStatus) {
        switch messageStatus {
        case .sending:
            if attachmentView.isHidden == false {
                attachmentView.readStatusLab.isHidden = true
                durationLab.isHidden = true
                listenVoiceView.isHidden = true
                messageContainerView.addAnimation()
            }
        case .success:
            if attachmentView.isHidden == false {
                attachmentView.readStatusLab.isHidden = false
                durationLab.isHidden = false
                listenVoiceView.isHidden = false
                messageContainerView.removeAnimation()
            }
        default:
            break
        }
    }
    
}
