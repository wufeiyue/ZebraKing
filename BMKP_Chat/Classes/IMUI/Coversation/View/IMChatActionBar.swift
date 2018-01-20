//
//  IMChatActionBar.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import Foundation
import UIKit

// 自定义键盘在delegate中处理
public protocol IMChatActionBarDelegate: class {
    
    /// 点击(文字)发送按钮
    ///
    /// - Parameter text: 发送的文字
    func sendTextBtnClick(text: String)
    
    /// 点击常用语按钮
    func commonSentenceBtnClick(sender: UIButton)

    /// 长按录音按钮
    ///
    /// - Parameters:
    ///   - sender: 长按手势
    func longPressVoiceButton(sender: UITapGestureRecognizer)
    
    /// switch按钮点击
    ///
    /// - Parameters:
    ///   - view: IMChatActionBar实例对象
    ///   - status: switch按钮的状态
    func chatActionBar(_ view: IMChatActionBar, btnStatus status: IMChatActionBarControlState)
    
}

public enum IMChatActionBarControlState {
    case normal     //文本输入框
    case disabled   //switch按钮不可用
    case selected   //语音文本框
}

public enum IMChatActionBarType {
    case normal
    case onlyText(String?)
}

public final class IMChatActionBar: UIView {
 
    public weak var delegate: IMChatActionBarDelegate?
    public var text: String {
        set {
            inputTextView.text = newValue
            inputTextView.updateTextView()
            
            if newValue.isEmpty == false {
                sendButton.isEnabled = true
            }
        }
        
        get {
            return inputTextView.text
        }
    }
    
    private lazy var inputTextView: IMTextView = { [unowned self] in
        let textView = IMTextView()
        textView.delegate = self
        textView.layer.borderWidth = 0.6
        textView.layer.borderColor = UIColor(red: 215.0/255, green: 215.0/255, blue: 215.0/255, alpha: 1).cgColor
        textView.layer.cornerRadius = 6
        return textView
    }()
    
    private lazy var commomSentenceBtn: UIButton = { [unowned self] in
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "chat_oftenused_normal"), for: .normal)
        btn.setImage(UIImage(named: "chat_oftenused_selected"), for: .highlighted)
        btn.addTarget(self, action: #selector(commomSentenceClick(sender:)), for: .touchUpInside)
        return btn
    }()
    
    private lazy var sendButton: UIButton = { [unowned self] in
        let btn = UIButton(type: .system)
        btn.setTitle("发送", for: .normal)
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        btn.setTitleColor(.white, for: .normal)
        btn.layer.cornerRadius = 2
        btn.setBackgroundColor(UIColor(hexString: "#666666"), forState: .normal)
        btn.setBackgroundColor(UIColor(hexString: "#D6D6D6"), forState: .disabled)
        btn.isHidden = false
        btn.isEnabled = !self.text.isEmpty
        btn.addTarget(self.superview, action: #selector(sendClick), for: .touchUpInside)
        return btn
    }()
    
    private lazy var recordButton: UIButton = { [unowned self] in
        let btn = UIButton(type: .custom)
        btn.setTitleColor(UIColor(hexString: "#707070"), for: .normal)
        btn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        btn.layer.borderWidth = 0.6
        btn.layer.borderColor = UIColor(red: 215.0/255, green: 215.0/255, blue: 215.0/255, alpha: 1).cgColor
        btn.layer.cornerRadius = 6
        btn.setTitle("按住 说话", for: .normal)
        btn.setTitle("松开 发送", for: .selected)
        btn.setBackgroundColor(UIColor(hexString: "#FCFCFC"), forState: .normal)
        btn.setBackgroundColor(UIColor(hexString: "#F0F0F0"), forState: .selected)
        btn.setBackgroundColor(UIColor(hexString: "#F0F0F0"), forState: .highlighted)
        //录音按钮事件交互
        let longPressG = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture))
        btn.addGestureRecognizer(longPressG)
        return btn
    }()
    
    public init(type: IMChatActionBarType) {
        super.init(frame: .zero)
        
        switch type {
        case .normal:
            //最常用的ActionBar 支持点击语音切换
            let normalModel: IMChatActionBarContainerViewModel = (UIImage(named:"chat_microphone"), fetchNormalView())
            let selectedModel: IMChatActionBarContainerViewModel = (UIImage(named:"chat_keyboard"), fetchSelectedView())
            let containerView = IMChatActionBarSwitchContainerView(normal: normalModel, selected: selectedModel)
            containerView.delegate = self
            addSubview(containerView)
            containerView.snp.makeConstraints { (m) in
                m.edges.equalToSuperview()
            }
        case .onlyText(let message):
            //仅支持纯文本的ActionBar
            let onlyTextContainerView = UIView()
            onlyTextContainerView.addSubview(sendButton)
            inputTextView.placeholder = message
            onlyTextContainerView.addSubview(inputTextView)
            
            sendButton.snp.makeConstraints { (m) in
                m.bottom.equalTo(-10)
                m.size.equalTo(CGSize(width: 44, height:30))
                m.right.equalTo(-8)
            }
            
            inputTextView.snp.makeConstraints { (m) in
                m.top.equalTo(5)
                m.bottom.equalTo(-5)
                m.left.equalTo(15)
                m.right.equalTo(sendButton.snp.left).offset(-5)
            }
            addSubview(onlyTextContainerView)
            onlyTextContainerView.snp.makeConstraints { (m) in
                m.edges.equalToSuperview()
            }
        }
        
    }
    
    private func fetchNormalView() -> UIView {
        let view = UIView()
        view.addSubview(inputTextView)
        view.addSubview(commomSentenceBtn)
        view.addSubview(sendButton)

        sendButton.snp.makeConstraints { (m) in
            m.bottom.equalTo(-10)
            m.size.equalTo(CGSize(width: 44, height:30))
            m.right.equalTo(-8)
        }

        commomSentenceBtn.snp.makeConstraints { (m) in
            m.right.equalTo(sendButton.snp.left).offset(-8)
            m.size.equalTo(CGSize(width: 28, height: 28))
            m.centerY.equalTo(sendButton)
        }

        inputTextView.snp.makeConstraints { (m) in
            m.top.equalTo(5)
            m.bottom.equalTo(-5)
            m.left.equalToSuperview()
            m.right.equalTo(commomSentenceBtn.snp.left).offset(-8)
        }
        
        return view
    }
    
    private func fetchSelectedView() -> UIView {
        let view = UIView()
        view.addSubview(recordButton)

        recordButton.snp.makeConstraints { (m) in
            m.top.equalTo(5)
            m.bottom.equalTo(-5)
            m.left.equalToSuperview()
            m.height.greaterThanOrEqualTo(38)
            m.right.equalTo(-8)
        }

        return view
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc
    private func handleLongPressGesture(sender: UITapGestureRecognizer) {
        if let delegate = self.delegate {
            delegate.longPressVoiceButton(sender: sender)
        }
        
        if sender.state == .began {
            recordButton.isSelected = true
        }
        else if sender.state == .ended {
            recordButton.isSelected = false
        }
    }
    
    @objc
    private func sendClick() {
        delegate?.sendTextBtnClick(text: inputTextView.text)
        inputTextView.text = ""
        inputTextView.placeholder = ""
        inputTextView.updateTextView()
        sendButton.isEnabled = false
    }
    
    /// 点击常用语按钮，显示或者隐藏常用语键盘
    ///
    /// - Parameter sender:
    @objc
    private func commomSentenceClick(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        delegate?.commonSentenceBtnClick(sender: sender)
    }
    

}
extension IMChatActionBar: IMChatActionBarContainerViewDelegate {
    public func chatActionBarContainerView(_ view: UIView, btnStatus status: IMChatActionBarControlState) {
        switch status {
        case .selected:
            inputTextView.resignResponder()
        case .normal:
            inputTextView.becomeResponder()
        default:
            break
        }
        delegate?.chatActionBar(self, btnStatus: status)
    }
}

extension IMChatActionBar: IMTextViewDelegate {
    public func textViewDidEndEditing(_ textView: UITextView) {
        
    }
    
    public func textViewDidChange(_ textView: UITextView) {
        sendButton.isEnabled = textView.text.characters.count  > 0
    }
    
    public func textViewShouldBeginEditing(_ textView: UITextView) -> Bool {
        return true
    }
    
    public func textView(_ textView: IMTextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" && textView.text.characters.count > 0 {
            delegate?.sendTextBtnClick(text: textView.text)
            textView.text = ""
            textView.updateTextView()
            sendButton.isEnabled = false
            return false
        }
        return true
    }
}

extension UIButton {
    public func setBackgroundColor(_ color: UIColor, forState: UIControlState) {
        UIGraphicsBeginImageContext(CGSize(width: 1, height: 1))
        UIGraphicsGetCurrentContext()?.setFillColor(color.cgColor)
        UIGraphicsGetCurrentContext()?.fill(CGRect(x: 0, y: 0, width: 1, height: 1))
        let colorImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        self.setBackgroundImage(colorImage, for: forState)
    }
}
