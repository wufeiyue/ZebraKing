//
//  IMChatViewController+SubViews.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import Foundation

//会话界面的键盘控制
extension IMChatViewController {
    
    /// 键盘控制
    func keyboardControl() {
        let notfiicationControl = NotificationCenter.default
        
        //键盘即将弹出
        notfiicationControl.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
            self?.keyboardControl(notification, isShowing: true)
        }
        
        //键盘即将要隐藏
        notfiicationControl.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
           self?.keyboardControl(notification, isShowing: true)
        }
        
    }
    

    ///  如果是自定义键盘 ，走自己 delegate 的处理键盘事件。
    ///
    /// - Parameters:
    ///   - notification: NSNotification 对象
    ///   - isShowing: 是否显示键盘？
    func keyboardControl(_ notification: Notification, isShowing: Bool) {
//        
//        //如果键盘弹出通知是由 添加常用语textView调出的,则不处理
//        if sentenceContainerView.inputIsFirstResponder {
//            return
//        }
        
        guard var userInfo = notification.userInfo else { return }
        let keybroadRect =  (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let curve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as AnyObject).uint32Value
        let convertedFrame = self.view.convert(keybroadRect!, from: nil)
        let heightOffset = self.view.bounds.size.height - convertedFrame.origin.y
        let options = UIViewAnimationOptions(rawValue: UInt(curve!) << 16
                     | UIViewAnimationOptions.beginFromCurrentState.rawValue)
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        self.chatActionBarView.snp.updateConstraints { (m) in
            if #available(iOS 11.0, *) {
                m.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-heightOffset)
            } else {
                m.bottom.equalTo(self.bottomLayoutGuide.snp.top).offset(-heightOffset)
            }
        }
        
        UIView.animate(withDuration:duration ?? 0.3, delay: 0, options: options, animations: {
            self.view.layoutIfNeeded()
            if isShowing && self.tableView.isScrolled {
                self.tableView.scrollToBottom(animated: false)
            }
        })
    }
    
    //隐藏键盘
    @objc
    func hideKeyBoard() {
        view.endEditing(true)
    }

}

extension IMChatViewController: IMDriverSentenceContainerViewDelegate {
    public func sentenceContainerView(_ view: IMDriverSentenceContainerView, didAddTapped btn: UIButton) {
        let commonSentenceVC = CommonSentenceViewController()
        commonSentenceVC.containerView = view
        commonSentenceVC.title = "添加常用语"
        let nav = UINavigationController(rootViewController: commonSentenceVC)
        present(nav, animated: true) {
            view.show()
        }
        view.hide()
    }
    
    public func sentenceContainerView(_ view: IMDriverSentenceContainerView, didSelect message: String) {
        chatActionBarView.text = message
    }
}

extension IMChatViewController: IMChatActionBarDelegate {
    
    /// 长按录音交互操作
    ///
    /// - Parameter sender: 长按录音的按钮
    public func longPressVoiceButton(sender: UITapGestureRecognizer) {
        
        switch sender.state {
        case .began: //长按开始
            soundRecorder.startRecording()
            if soundRecorder.isVaildRecorder {
                voiceIndicatorView?.recording()
            }
        case .changed: //长按时移动
            guard soundRecorder.recordState.value != .stop, let voiceIndicatorView = self.voiceIndicatorView else { return }
            let point = sender.location(in: voiceIndicatorView)
            if voiceIndicatorView.point(inside: point, with: nil) {
                voiceIndicatorView.slideToCancelRecord()
            } else {
                voiceIndicatorView.recording()
            }
        case .ended: //长按结束
            guard soundRecorder.recordState.value != .stop else { return }
            voiceIndicatorView?.endRecord()
            if voiceIndicatorView?.isFinishRecording == true {
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
    
    
    /// 发送按钮点击事件
    ///
    /// - Parameter text: textView的内容
    public func sendTextBtnClick(text: String) {
        let message = IMMessage.msgWithText(text: text)
        onMessageWillSend(msg: message)
        sendMsg(msg: message)
    }
    
    public func commonSentenceBtnClick(sender: UIButton) {
        hideKeyBoard()
        sentenceContainerView.show()
    }
    
    
    public func chatActionBar(_ view: IMChatActionBar, btnStatus status: IMChatActionBarControlState) {
    
        if status == .selected {
            //语音输入框
            view.endEditing(true)
            soundRecorder.checkIsVaildRecordIfNeeded()
        }
        else if status == .normal {
            //文本输入框
            
        }
        
        //创建录音提示视图
        if voiceIndicatorView == nil {
            setupVoiceIndicatorView()
        }
        
    }
    
    func audioRecordStateChanged(_ state: ChatRecorderState) {
        switch state {
        case .maxRecord:    //最大录音
            voiceIndicatorView?.endRecord()
        case .relaseCancel: //取消
//            voiceIndicatorView?.slideToCancelRecord()
            onMessageCancelSend()
        case .tooShort:     //时间太短
            voiceIndicatorView?.messageTooShort()
            //这里注释,主要因为这时候还没有向数组中,增加一条message. 执行到这里就会从数组中移除一条, 不合理
//            onMessageCancelSend()
        case .prepare:      //准备好了
            let emptyMsg = IMMessage.msgWithEmptySound()
            onMessageWillSend(msg: emptyMsg)
        default:
            break
        }
    }
    
    /// 初始化录音状态提示器
    private func setupVoiceIndicatorView() {
        let voiceIndicatorView = IMVoiceIndicator()
        voiceIndicatorView.isHidden = true
        view.addSubview(voiceIndicatorView)
        voiceIndicatorView.snp.makeConstraints {(make) -> Void in
            make.top.equalTo(100)
            make.left.right.equalToSuperview()
            make.bottom.equalTo(-100)
        }
        
        self.voiceIndicatorView = voiceIndicatorView
    }
    
}

extension IMChatViewController: IMChatAudioRecordDelegate {
    
    /**
     录音完成
     - parameter recordTime:          录音时长
     - parameter uploadAmrData:     上传的 amr Data
     */
    func audioRecordFinish(_ uploadAmrData: Data, recordTime: TimeInterval) {
        guard let soundMsg = IMMessage.msgWithSound(data: uploadAmrData, dur: Int32(recordTime)) else { return }
        dispatch_async_safely_to_main_queue { [weak self] in
            self?.replaceLastMessage(newMsg: soundMsg)
            self?.sendMsg(msg: soundMsg)
        }
    }
    
}

// 文字输入代理方法
extension IMChatViewController {
    
    /// 点击常用语键盘cell发送文字
    ///
    /// - Parameter msg: 发送的内容
    func sendCellMessage(msg: String) {
        let msgSend = IMMessage.msgWithText(text: msg)
        onMessageWillSend(msg: msgSend)
        sendMsg(msg: msgSend)
    }
    
}

public extension UITableView {
    var isScrolled: Bool {
        return contentSize.height > bounds.size.height
    }
    
    func scrollToBottom(animated: Bool) {
        let bottomOffset = CGPoint(x: 0, y:self.contentSize.height - self.bounds.size.height)
        self.setContentOffset(bottomOffset, animated: animated)
    }
}
