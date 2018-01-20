//
//  IMVoiceIndicator.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//  

import Foundation
import UIKit
import DynamicColor

public class IMVoiceIndicator: UIView {
    
    //是否完成录音
    private(set) var isFinishRecording: Bool = false
    
    private lazy var containerView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 4
        view.layer.masksToBounds = true
        view.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return view
    }()
    
    private lazy var recordingBkg: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named:"chat_recordingBkg")
        return view
    }()
    
    private lazy var noteLabel: UILabel = {
        let label = UILabel()
        label.layer.cornerRadius = 2.0
        label.layer.masksToBounds = true
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()
    
    //音量的图片
    private lazy var signalValueImageView: UIImageView = {
        let imageView = UIImageView()
        return imageView
    }()
    
    //录音整体的 view，控制是否隐藏
    private lazy var recordingView: UIView = UIView()
    
    //录音时间太短的提示
    private lazy var tooShotPromptImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named:"chat_messageTooShort")
        return imageView
    }()
    
    //取消提示
    private lazy var cancelImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named:"chat_recordCancel")
        return imageView
    }()
    
    override init (frame : CGRect) {
        super.init(frame : frame)
        self.initContent()
    }
    
    convenience init () {
        self.init(frame:CGRect.zero)
        self.initContent()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func initContent() {
        
        addSubview(containerView)
        containerView.snp.makeConstraints {(make) -> Void in
            make.size.equalTo(CGSize(width: 150, height: 150))
            make.center.equalToSuperview()
        }
        
        containerView.addSubview(noteLabel)
        containerView.addSubview(cancelImageView)
        containerView.addSubview(tooShotPromptImageView)
        containerView.addSubview(recordingView)
        recordingView.addSubview(recordingBkg)
        recordingView.addSubview(signalValueImageView)
        
        noteLabel.snp.makeConstraints { (m) in
            m.left.right.equalToSuperview().inset(8)
            m.bottom.equalToSuperview().offset(-6)
            m.height.equalTo(20)
        }
        
        cancelImageView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize(width: 100, height:100))
            m.centerY.equalToSuperview().offset(-10)
            m.centerX.equalToSuperview()
        }
        
        tooShotPromptImageView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize(width: 100, height:100))
            m.centerY.equalToSuperview().offset(-10)
            m.centerX.equalToSuperview()
        }
        
        recordingView.snp.makeConstraints { (m) in
            m.size.equalTo(CGSize(width: 100, height:100))
            m.centerY.equalToSuperview().offset(-10)
            m.centerX.equalToSuperview()
        }
        
        recordingBkg.snp.makeConstraints { (m) in
            m.width.equalTo(62)
            m.top.bottom.left.equalToSuperview()
        }
        
        signalValueImageView.snp.makeConstraints { (m) in
            m.top.right.bottom.equalToSuperview()
            m.width.equalTo(38)
        }
    }
    
}

//对外交互的 view 控制
extension  IMVoiceIndicator{
    //正在录音
    func recording() {
        isHidden = false
        cancelImageView.isHidden = true
        tooShotPromptImageView.isHidden = true
        recordingView.isHidden = false
        noteLabel.backgroundColor = UIColor.clear
        noteLabel.text = "手指上滑，取消发送"
        isFinishRecording = true
    }
    
    //录音过程中音量的变化
    func signalValueChanged(_ value: CGFloat) {
        
    }
    
    //滑动取消
    func slideToCancelRecord() {
        guard isHidden == false else { return }
        cancelImageView.isHidden = false
        tooShotPromptImageView.isHidden = true
        recordingView.isHidden = true
        noteLabel.backgroundColor = UIColor(hexString: "#9C3638")
        noteLabel.text = "松开手指，取消发送"
        isFinishRecording = false
    }
    
    //录音时间太短的提示
    func messageTooShort() {
        isHidden = false
        cancelImageView.isHidden = true
        tooShotPromptImageView.isHidden = false
        recordingView.isHidden = true
        noteLabel.backgroundColor = UIColor.clear
        noteLabel.text = "说话时间太短"
        //0.5秒后消失
        let delayTime = DispatchTime.now() + 0.5
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.endRecord()
        }
    }
    
    //录音结束
    func endRecord() {
        isHidden = true
    }
    
    //更新麦克风的音量大小
    func updateMetersValue(_ value: Int) {
        let array = [
              UIImage(named: "chat_recordingSignal001"),
              UIImage(named: "chat_recordingSignal002"),
              UIImage(named: "chat_recordingSignal003"),
              UIImage(named: "chat_recordingSignal004"),
              UIImage(named: "chat_recordingSignal005")
            ]
        self.signalValueImageView.image = array[value]
        
    }
}
