//
//  CommonConversationViewController.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/13.
//

import Foundation

open class CommonConversationViewController: ConversationViewController, ConversationInputBarDelegate {
    
    open lazy var conversationInputBar: ConversationInputBar = { [unowned self] in
        let bar = ConversationInputBar()
        bar.delegate = self
        bar.status = .normal
        bar.backgroundColor = UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1.0)
        return bar
    }()
    
    //音频指示器
    open lazy var voiceIndicator: VoiceIndicatorView = setupVoiceIndicatorView()
    
    //音频输入类 因为子类重写需要调用, 这里放开作用域
    open lazy var soundRecorder: ChatSoundRecorder = ChatSoundRecorder(delegate: self)
    
    //播放管理类
    lazy var chatAudioPlay = IMChatAudioPlayManager()
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground, object: nil, queue: nil) { _ in
            self.task.active()
        }

        NotificationCenter.default.addObserver(forName: .UIApplicationWillResignActive, object: nil, queue: nil) { _ in
            self.task.resign()
        }
        
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
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
        messageInputBar.inputTextView.resignFirstResponder()
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
    
    public func inputBar(_ bar: ConversationInputBar, senderBtnDidTapped btn: UIButton) {
        guard let text = bar.inputTextView.text, text.isEmpty == false else {
            showToast(message: "输入的内容不能为空")
            return
        }
        let message = MessageElem(text: text, sender: currentSender())
        onMessageWillSend(message)
        sendMsg(msg: message)
    }
    
    public func inputBar(_ bar: ConversationInputBar, recordBtnLongPressGesture gesture: UIGestureRecognizer) {
        switch gesture.state {
        case .began: //长按开始
            soundRecorder.startRecording()
            guard soundRecorder.isVaildRecorder else {
                return
            }
            voiceIndicator.recording()
            
        case .changed: //长按时移动
            guard soundRecorder.recordState != .stop else {
                return
            }
            voiceIndicator.recognizerChanged(sender: gesture)
            
        case .ended: //长按结束
            guard soundRecorder.recordState != .stop else {
                return
            }
            voiceIndicator.endRecord()
            if voiceIndicator.isFinishRecording {
                //结束录音
                soundRecorder.stopRecord()
            } else {
                //取消录音
                soundRecorder.cancelRecord()
            }
            
        default:
            break
        }
        
    }
    
    public func audioRecordStateDidChange(_ status: ChatRecorderState) {
        switch status {
        case .maxRecord:    //最大录音
            voiceIndicator.endRecord()
        case .relaseCancelDidPrepare: //取消
            onMessageCancelSend()
        case .tooShort:     //时间太短
            voiceIndicator.messageTooShort()
        case .prepare:      //准备好了
            //TODO: 插入一个空的音频文件
            let msg = MessageElem(data: Data(), dur: 0, sender: currentSender())
            onMessageWillSend(msg)
        default:
            break
        }
    }
    
    public func audioRecordPeakDidChange(_ value: Int) {
        voiceIndicator.updateMetersValue(value - 1)
    }
    
    public func audioRecordFinish(_ uploadAmrData: Data, recordTime: TimeInterval) {
        //TODO: 替换最后一个消息, 发送消息
        let soundMsg = MessageElem(data: uploadAmrData, dur: Int32(recordTime), sender: currentSender())
        replaceLastMessage(newMsg: soundMsg)
        sendMsg(msg: soundMsg)
    }
    
    /// 请求录音权限失败的处理
    public func audioRecordRequestPermissionFailure() {
        let alertVC = UIAlertController(title: "\"\(Bundle.displayName)\"想访问您的麦克风", message: "只有打开麦克风,才可以发送语音哦~", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "不允许", style: .cancel, handler: nil))
        alertVC.addAction(UIAlertAction(title: "好", style: .default, handler: { (action) in
            if let url = URL(string: UIApplicationOpenSettingsURLString) {
                UIApplication.shared.openURL(url)
            }
        }))
        present(alertVC, animated: true, completion: nil)
    }
    
}

extension VoiceIndicatorView {
    fileprivate func recognizerChanged(sender: UIGestureRecognizer) {
        let location = sender.location(in: self)
        if point(inside: location, with: nil) {
            slideToCancelRecord()
        } else {
            recording()
        }
    }
}

