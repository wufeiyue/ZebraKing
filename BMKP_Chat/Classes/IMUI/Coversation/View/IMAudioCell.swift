
//
//  IMChatVoiceCell.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import Foundation
import Kingfisher
import ImSDK
import IMMessageExt

public class IMAudioCell: IMBaseCell  {
    
    lazy var listenVoiceBtn: UIButton = { [unowned self] in
        let btn = UIButton(type: .custom)
        btn.imageView?.animationDuration = 1
        btn.isSelected  = false
        btn.backgroundColor = .clear
        btn.addTarget(self, action: #selector(playingTap), for: .touchUpInside)
        return btn
    }()
    
    lazy var durationLab: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = UIColor(red: 128.0/255, green: 128.0/255, blue: 128.0/255, alpha: 1)
        label.isHidden = true
        return label
    }()
    
    override public func createView() {
        super.createView()
        [listenVoiceBtn, durationLab, playGif].forEach { contentView.addSubview($0) }
    }
    
    override public func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func configContentView(_ model: IMMessage, receiver: IMUserUnit) {
        super.configContentView(model, receiver: receiver)
    
        if model.isMineMsg {
            if model.status == .create {
                self.retryButton.isHidden = true
                self.durationLab.isHidden = true
                self.activityView.isHidden = true
                self.readStatusLab.isHidden = true
            } else if model.status == .sending {
                self.retryButton.isHidden = true
                self.durationLab.isHidden = true
                self.activityView.isHidden = false
                self.readStatusLab.isHidden = true
                self.activityView.startAnimating()
            } else if model.status == .sendFail {
                self.retryButton.isHidden = false
                self.durationLab.isHidden = true
                self.activityView.isHidden = true
                self.readStatusLab.isHidden = true
                self.activityView.stopAnimating()
            } else if model.status == .sendSucc {
                self.retryButton.isHidden = true
                self.durationLab.isHidden = false
                self.activityView.isHidden = true
                if receiver.role == .server {
                    self.readStatusLab.isHidden = true
                }
                else {
                    self.readStatusLab.isHidden = false
                }
                self.activityView.stopAnimating()
            }
        } else {
            self.retryButton.isHidden = true
            self.durationLab.isHidden = false
            self.activityView.isHidden = true
            self.readStatusLab.isHidden = true
        }
        if let second = (model.msg.getElem(0) as? TIMSoundElem)?.second {
            self.durationLab.text = second < 1 ? "" : "\(second)\""
            self.playGif.image = nil
        }
        let strechImg = model.isMineMsg ? UIImage.init(named: "chat_text-area-blue") : UIImage.init(named: "chat_text-area-white")
        let BGimg = strechImg?.resizableImage(withCapInsets: UIEdgeInsetsMake((strechImg?.size.height)! * 0.5, (strechImg?.size.width)! * 0.5, (strechImg?.size.height)! * 0.5  , (strechImg?.size.width)! * 0.5 )  , resizingMode: .stretch)
        listenVoiceBtn.setBackgroundImage(BGimg, for: .normal)
        listenVoiceBtn.contentHorizontalAlignment = model.isMineMsg ? .right : .left
        self.msgModel = model
        self.resetVoiceButton()
        self.setNeedsLayout()
        
    }

    
    lazy var playGif: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    @objc func playingTap(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        if sender.isSelected {
            startPlayVoiceBtnChange()
        }else{
            resetVoiceButton()
        }
        if let delegate = self.delegate {
            delegate.cellDidTapedVoiceButton(self, isPlayingVoice: sender.isSelected)
        }
        
    }
    
    private func resetVoiceButton(){
        guard let model = self.msgModel else {
            return
        }
        if model.isMineMsg {
            playGif.image = UIImage.init(named: "chat_soundwave_w_n")
        }else{
            playGif.image = UIImage.init(named: "chat_soundwave_b_n")
        }
        
    }
    
    private func startPlayVoiceBtnChange(){
        guard let model = self.msgModel else {
            return
        }
        if model.isMineMsg {
            playGif.kf.setImage(with: URL(fileURLWithPath: Bundle.chatResources.path(forResource: "chat_soundwave_w_s", ofType: "gif")!))
        }else{
            playGif.kf.setImage(with: URL(fileURLWithPath: Bundle.chatResources.path(forResource: "chat_soundwave_b_s", ofType: "gif")!))
        }
    }
    
    
    public func stopPlayVoice() {
        listenVoiceBtn.isSelected = false
        resetVoiceButton()
    }
    

    override public func layoutSubviews() {
        super.layoutSubviews()
        guard let model = self.msgModel,
            let duration = (model.msg.getElem(0) as? TIMSoundElem)?.second
        else {
            return
        }
        
        let voicelength = 70 + 130 * (CGFloat(duration)/60)
        listenVoiceBtn.frame.size = CGSize.init(width: min(voicelength, kChatVoiceMaxWidth), height: kChatBGViewHeight)
        durationLab.sizeToFit()
        if model.isMineMsg {
            listenVoiceBtn.frame.origin.x = UIScreen.main.bounds.size.width - kUserPicMarginLeading - kUserPicWidth - kChatBGImgMaginLeft - voicelength
            durationLab.frame.origin.x = listenVoiceBtn.frame.origin.x - 6 - durationLab.frame.size.width
            durationLab.textAlignment = .right
        }else{
            listenVoiceBtn.frame.origin.x = kChatBGViewLeft
            durationLab.frame.origin.x = listenVoiceBtn.frame.maxX + 6
            durationLab.textAlignment = .left
        }
        listenVoiceBtn.frame.origin.y = 0
        durationLab.frame.origin.y = listenVoiceBtn.frame.origin.y + 0.25 * listenVoiceBtn.frame.size.height
        durationLab.frame.size.height = listenVoiceBtn.frame.size.height * 0.5
//        durationLab.frame.size.width = 80
        listenVoiceBtn.imageEdgeInsets = model.isMineMsg ? UIEdgeInsetsMake(kChatTextMarginBottom, 0, 0, voicelength * 0.5 - 8) : UIEdgeInsetsMake(-kChatTextMarginBottom, voicelength * 0.5 - 8, 0, 0)
        
        playGif.frame.size = CGSize.init(width: 16, height: 18)
        playGif.center = listenVoiceBtn.center
        
        activityView.center = CGPoint(x: self.listenVoiceBtn.frame.origin.x - 20, y: self.listenVoiceBtn.center.y)
        retryButton.center = CGPoint(x: self.listenVoiceBtn.frame.origin.x - 20, y: self.listenVoiceBtn.center.y)
        readStatusLab.center = CGPoint(x: self.durationLab.frame.origin.x - 20, y: self.listenVoiceBtn.center.y)
    }
    
    class func layoutHeight(_ model: IMMessage) -> CGFloat {
        return 52
    }
}
