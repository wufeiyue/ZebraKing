//
//  ConversationInputBar.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/4/2.
//

import UIKit

public protocol ConversationInputBarDelegate: class {
    
    /// 控制手柄点击回调
    ///
    /// - Parameters:
    ///   - view: 工具条视图
    ///   - btn: 控制手柄按钮对象
    func inputBar(_ bar: ConversationInputBar, controlBtnDidTapped btn: UIButton)
    
    /// 发送按钮点击回调
    ///
    /// - Parameters:
    ///   - view: 工具条视图
    ///   - btn: 发送按钮对象
    func inputBar(_ bar: ConversationInputBar, senderBtnDidTapped btn: UIButton)
    
    /// 录音按钮点击回调
    ///
    /// - Parameters:
    ///   - view: 工具条视图
    ///   - btn: 录音按钮对象
    func inputBar(_ bar: ConversationInputBar, recordBtnDidTapped btn: UIButton)
    
    /// 录音按钮长按回调
    ///
    /// - Parameters:
    ///   - view: 工具条视图
    ///   - gesture: 长按手势
    func inputBar(_ bar: ConversationInputBar, recordBtnLongPressGesture gesture: UIGestureRecognizer)
}

extension ConversationInputBarDelegate {
    public func inputBar(_ bar: ConversationInputBar, controlBtnDidTapped btn: UIButton) {}
    public func inputBar(_ bar: ConversationInputBar, senderBtnDidTapped btn: UIButton) {}
    public func inputBar(_ bar: ConversationInputBar, recordBtnDidTapped btn: UIButton) {}
    public func inputBar(_ bar: ConversationInputBar, recordBtnLongPressGesture gesture: UIGestureRecognizer) {}
}

open class ConversationInputBar: MessageInputBar {
    
    //控制手柄
    open var controlBtn: UIButton!
    
    //发送按钮
    open var senderBtn: UIButton!
    
    //录音按钮
    open var recordBtn: UIButton!
    
    //normal or selected
    public var status: UIControl.State = .normal {
        didSet {
            displayViewByStatus()
        }
    }
    
    
    public weak var delegate: ConversationInputBarDelegate?
    
    //MARK: - 改变样式
    
    open override func setupConstraints() {
        
        contentView.translatesAutoresizingMaskIntoConstraints = false
        controlBtn.translatesAutoresizingMaskIntoConstraints = false
        senderBtn.translatesAutoresizingMaskIntoConstraints = false
        inputTextView.translatesAutoresizingMaskIntoConstraints = false
        recordBtn.translatesAutoresizingMaskIntoConstraints = false
        
        addConstraints([
            
            NSLayoutConstraint(item: contentView, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: padding.top),
            NSLayoutConstraint(item: contentView, attribute: .bottom, relatedBy: .equal, toItem: self, attribute: .bottom, multiplier: 1.0, constant: -padding.bottom),
            NSLayoutConstraint(item: contentView, attribute: .leading, relatedBy: .equal, toItem: self, attribute: .leading, multiplier: 1.0, constant: 0),
            NSLayoutConstraint(item: contentView, attribute: .trailing, relatedBy: .equal, toItem: self, attribute: .trailing, multiplier: 1.0, constant: 0)
            
        ])
        
        
        let list: Array<NSLayoutConstraint> = [
        
        NSLayoutConstraint(item: controlBtn, attribute: .leading, relatedBy: .equal, toItem: contentView, attribute: .leading, multiplier: 1.0, constant: 0),
        NSLayoutConstraint(item: controlBtn, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: -3),
        NSLayoutConstraint(item: controlBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 33),
        NSLayoutConstraint(item: controlBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 50),
            
        NSLayoutConstraint(item: senderBtn, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: -8),
        NSLayoutConstraint(item: senderBtn, attribute: .bottom, relatedBy: .equal, toItem: controlBtn, attribute: .bottom, multiplier: 1.0, constant: 0),
        NSLayoutConstraint(item: senderBtn, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1.0, constant: 33),
        NSLayoutConstraint(item: senderBtn, attribute: .width, relatedBy: .equal, toItem: nil, attribute: .width, multiplier: 1.0, constant: 44),
        
        NSLayoutConstraint(item: inputTextView, attribute: .leading, relatedBy: .equal, toItem: controlBtn, attribute: .trailing, multiplier: 1.0, constant: 0),
        NSLayoutConstraint(item: inputTextView, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0),
        NSLayoutConstraint(item: inputTextView, attribute: .trailing, relatedBy: .equal, toItem: senderBtn, attribute: .leading, multiplier: 1.0, constant: -8),
        
        NSLayoutConstraint(item: recordBtn, attribute: .leading, relatedBy: .equal, toItem: controlBtn, attribute: .trailing, multiplier: 1.0, constant: 0),
        NSLayoutConstraint(item: recordBtn, attribute: .top, relatedBy: .equal, toItem: contentView, attribute: .top, multiplier: 1.0, constant: 0),
        NSLayoutConstraint(item: recordBtn, attribute: .bottom, relatedBy: .equal, toItem: contentView, attribute: .bottom, multiplier: 1.0, constant: 0),
        NSLayoutConstraint(item: recordBtn, attribute: .trailing, relatedBy: .equal, toItem: contentView, attribute: .trailing, multiplier: 1.0, constant: -10)
        
        ]
        
        contentView.addConstraints(list)

    }
    
    open override func setupSubviews() {
        super.setupSubviews()
        
        controlBtn = UIButton()
        controlBtn.setImage(MessageStyle.microphone.image, for: .normal)
        controlBtn.setImage(MessageStyle.keyboard.image, for: .selected)
        controlBtn.imageView?.contentMode = .scaleAspectFit
        controlBtn.addTarget(self, action: #selector(controlBtnDidTapped(sender:)), for: .touchUpInside)
        contentView.addSubview(controlBtn)
        
        senderBtn = UIButton()
        senderBtn.backgroundColor = .gray
        senderBtn.setTitle("发送", for: .normal)
        senderBtn.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        senderBtn.setTitleColor(.white, for: .normal)
        senderBtn.layer.cornerRadius = 2
        //      btn.isEnabled = !inputTextView.text.isEmpty
        senderBtn.addTarget(self, action: #selector(senderBtnDidTapped(sender:)), for: .touchUpInside)
        contentView.addSubview(senderBtn)
        
        recordBtn = UIButton(type: .custom)
        recordBtn.setTitleColor(UIColor(red: 100/255.0, green: 100/255.0, blue: 100/255.0, alpha: 1), for: .normal)
        recordBtn.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        recordBtn.layer.borderWidth = 0.6
        recordBtn.layer.borderColor = UIColor(red: 215.0/255, green: 215.0/255, blue: 215.0/255, alpha: 1).cgColor
        recordBtn.layer.cornerRadius = 6
        recordBtn.setTitle("按住 说话", for: .normal)
        recordBtn.setTitle("松开 发送", for: .selected)
        
        //录音按钮事件交互
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPressGesture))
        recordBtn.addGestureRecognizer(longPressGesture)
        contentView.addSubview(recordBtn)
    }
    
    /// 显示视图
    private func displayViewByStatus() {
        if status == .normal {
            //默认文本输出的样式
            senderBtn.alpha = 1
            senderBtn.isHidden = false
            
            inputTextView.alpha = 1
            inputTextView.isHidden = false
            inputTextView.becomeFirstResponder()
            
            recordBtn.isHidden = true
            recordBtn.alpha = 0
            
        }
        else if status == .selected {
            //默认为语音输出的样式
            
            UIView.animate(withDuration: 0.3, animations: {
                self.senderBtn?.alpha = 0
                self.inputTextView.alpha = 0
            }) { _ in
                self.senderBtn?.isHidden = true
                self.inputTextView.isHidden = true
            }
            
            recordBtn.alpha = 0
            recordBtn.isHidden = false
            inputTextView.resignFirstResponder()
            
            UIView.animate(withDuration: 0.3) {
                self.recordBtn.alpha = 1
            }
        }
    }
    
    
    //MARK: - 传递响应者链
    
    @objc
    private func controlBtnDidTapped(sender: UIButton) {
        sender.isSelected = !sender.isSelected
        delegate?.inputBar(self, controlBtnDidTapped: sender)
    }
    
    @objc
    private func senderBtnDidTapped(sender: UIButton) {
        delegate?.inputBar(self, senderBtnDidTapped: sender)
        //更新self和inputTextView的高度
        if inputTextView.canUpdateIntrinsicContentHeight() {
            invalidateIntrinsicContentSize()
        }
    }
    
    @objc
    private func handleLongPressGesture(gesture: UIGestureRecognizer) {
        delegate?.inputBar(self, recordBtnLongPressGesture: gesture)
    }
    
    @objc
    private func recordBtnDidTapped(sender: UIButton) {
        delegate?.inputBar(self, recordBtnDidTapped: sender)
    }
}
