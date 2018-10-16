//
//  CommonConversationViewController.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/13.
//

import Foundation

open class CommonConversationViewController: ConversationViewController, ConversationInputBarDelegate {
    
    open var conversationInputBar: ConversationInputBar!
    
    //音频指示器
    lazy var voiceIndicator: VoiceIndicatorView = setupVoiceIndicatorView()
    
    //音频输入类
    lazy var soundRecorder: ChatSoundRecorder = ChatSoundRecorder(delegate: self)
    
    //播放管理类
    lazy var chatAudioPlay = IMChatAudioPlayManager()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
     
        conversationInputBar = ConversationInputBar()
        conversationInputBar.delegate = self
        conversationInputBar.status = .normal
        conversationInputBar.backgroundColor = UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1.0)
        
    }
    
    /// 自定义底部工具栏
    open override var messageInputBar: MessageInputBar! {
        return conversationInputBar
    }
    
    open func setupVoiceIndicatorView() -> VoiceIndicatorView {
        
        let indicator = VoiceIndicatorView()
        indicator.isHidden = true
        
        view.addSubview(indicator)
        
        indicator.translatesAutoresizingMaskIntoConstraints = false
        
        var constraints: Array<NSLayoutConstraint> = Array<NSLayoutConstraint>()
        
        if #available(iOS 11.0, *) {
            constraints.append(NSLayoutConstraint(item: indicator, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1.0, constant: 100))
            constraints.append(NSLayoutConstraint(item: indicator, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: -100))
            
        } else {
            constraints.append(NSLayoutConstraint(item: indicator, attribute: .top, relatedBy: .equal, toItem: self.topLayoutGuide, attribute: .top, multiplier: 1.0, constant: 100))
            constraints.append(NSLayoutConstraint(item: indicator, attribute: .bottom, relatedBy: .equal, toItem: self.bottomLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: -100))
        }
        
        constraints.append(NSLayoutConstraint(item: indicator, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: indicator, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0))
        
        view.addConstraints(constraints)
        
        return indicator
    }
    
    public override func didContainer(in cell: MessageCollectionViewCell, message: MessageType) {
        conversationInputBar.inputTextView.resignFirstResponder()
    }
    
    public override func didTapMessage(in cell: MessageCollectionViewCell, message: MessageType) {
        
        let currentIndexPath = messagesCollection.indexPath(for: cell)
        
        if let audioCell = cell as? AudioMessageCell {
            
            /*
             1.selectedIndexPath为空,表示初始设置, 当前cell为第一响应者
             2.selectedIndexPath不为空, 点击判断是否为同一个对象
             3. 是同一个对象: 停止播放
             4. 不是同一个对象: selectedCell置为初始状态, 新的cell为第一响应者, 并赋值给selectedIndexPath
             5. 自动暂停: 将selectedCell置为初始状态
             */
            
            var selectedAudioCell: AudioMessageCell? {
                guard let indexPath = selectedIndexPath else { return nil }
                return messagesCollection.cellForItem(at: indexPath) as? AudioMessageCell
            }
            
            var availableVoice: Bool = false
            
            if let unwrappedSelectedIndexPath = selectedIndexPath {
                
                if let unwrappedSelectedAudioCell = selectedAudioCell, messagesCollection.visibleCells.contains(unwrappedSelectedAudioCell) {
                    selectedAudioCell?.normalAudio()
                }
                else {
                    selectedIndexPath = nil
                }
                
                chatAudioPlay.stopPlay()
                availableVoice = (unwrappedSelectedIndexPath != currentIndexPath)
            }
            else {
                availableVoice = true
            }
            
            if availableVoice {
                
                audioCell.selectedAudio()
                selectedIndexPath = currentIndexPath
                
                if let imMessage = message as? MessageElem {
                    playAudio(message: imMessage) { [weak self] (description) in
                        if let unwrappedSelectedAudioCell = selectedAudioCell {
                            unwrappedSelectedAudioCell.normalAudio()
                        }
                        else {
                            audioCell.normalAudio()
                        }
                        self?.selectedIndexPath = nil

                        if let unwrappedDescription = description, unwrappedDescription.isEmpty == false {
                            self?.showToast(message: unwrappedDescription)
                        }

                    }
                }
            }
            else {
                selectedIndexPath = nil
            }
        }
        
    }
    
    public func playAudio(message: MessageElem, result: @escaping (String?) -> Void) {
        
        message.getSoundPath(succ: { [weak self](url) in
            
                guard let unwrappedURL = url else {
                    result("暂未找到读取语音的资源")
                    return
                }
            
                self?.chatAudioPlay.playWith(url: unwrappedURL, finish: {
                    result(nil)
                })
            
            }, fail: { (_, str) in
                result(str)
        })
    }
    
    /// 录音按钮点击回调
    ///
    /// - Parameters:
    ///   - view: 工具条视图
    ///   - btn: 录音按钮对象
    open func inputBar(_ bar: ConversationInputBar, recordBtnDidTapped btn: UIButton) { }

    /// 控制手柄点击回调
    ///
    /// - Parameters:
    ///   - view: 工具条视图
    ///   - btn: 控制手柄按钮对象public
    public func inputBar(_ bar: ConversationInputBar, controlBtnDidTapped btn: UIButton) {
        
        if bar.status == .normal {
            bar.status = .selected
        }
        else {
            bar.status = .normal
        }
        
        switch bar.status {
        case .normal:
            break
        case .selected:
            //已切换到音频输入模式
            soundRecorder.checkIsVaildRecordIfNeeded()
        default:
            break
        }
        
    }
    
    /// 发送按钮点击回调
    ///
    /// - Parameters:
    ///   - view: 工具条视图
    ///   - btn: 发送按钮对象public
    public func inputBar(_ bar: ConversationInputBar, senderBtnDidTapped btn: UIButton) {
        guard let text = bar.inputTextView.text, text.isEmpty == false else {
            showToast(message: "输入的内容不能为空")
            return
        }
        let message = MessageElem(text: text, sender: currentSender())
//        message.receiver = currentSender()
        onMessageWillSend(message)
        sendMsg(msg: message)
    }
    
    /// 录音按钮长按回调
    ///
    /// - Parameters:
    ///   - view: 工具条视图
    ///   - gesture: 长按手势
    public func inputBar(_ bar: ConversationInputBar, recordBtnLongPressGesture gesture: UIGestureRecognizer) {
        longPressVoiceButton(sender: gesture)
    }
}

