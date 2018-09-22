//
//  ConversationViewController+Recorder.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/12.
//

import Foundation

/*
 使用场景:
 
 //切换音频和文本消息时, 需要调用下面方法
 soundRecorder.checkIsVaildRecordIfNeeded()
 
 //在长按录音按钮时, 需要调用下面方法
 longPressVoiceButton()
 
 除此以外, 不需要在别的地方手动调用 voiceIndicator或soundRecorder的实例方法
 
 */

extension CommonConversationViewController: ChatAudioRecordDelegate {
    
    public func audioRecordStateDidChange(_ status: ChatRecorderState) {
        audioRecordStateChanged(status)
    }
    
    public func audioRecordPeakDidChange(_ value: Int) {
        DispatchQueue.main.async { [weak self] in
            self?.voiceIndicator.updateMetersValue(value - 1)
        }
    }
    
    /**
     录音完成
     - parameter recordTime:        录音时长
     - parameter uploadAmrData:     上传的 amr Data
     */
    public func audioRecordFinish(_ uploadAmrData: Data, recordTime: TimeInterval) {
        //TODO: 替换最后一个消息, 发送消息
        guard let soundMsg = IMMessage.msgWithSound(data: uploadAmrData, dur: Int32(recordTime)) else { return }
        soundMsg.receiver = currentSender()
        dispatch_async_safely_to_main_queue { [weak self] in
            self?.replaceLastMessage(newMsg: soundMsg)
            self?.sendMsg(msg: soundMsg)
        }
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
    
    /// 长按录音交互操作
    ///
    /// - Parameter sender: 长按录音的按钮
    public func longPressVoiceButton(sender: UIGestureRecognizer) {
        
        switch sender.state {
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
            voiceIndicator.recognizerChanged(sender: sender)
            
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
    
    private func audioRecordStateChanged(_ status: ChatRecorderState) {
        DispatchQueue.main.async { [weak self] in
            switch status {
            case .maxRecord:    //最大录音
                self?.voiceIndicator.endRecord()
            case .relaseCancelDidPrepare: //取消
                self?.onMessageCancelSend()
            case .tooShort:     //时间太短
                self?.voiceIndicator.messageTooShort()
            case .prepare:      //准备好了
                //TODO: 插入一个空的音频文件
                let emptyMsg = IMMessage.msgWithEmptySound()
                emptyMsg.receiver = self?.currentSender()
                self?.onMessageWillSend(emptyMsg)
                break
            default:
                break
            }
        }
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
