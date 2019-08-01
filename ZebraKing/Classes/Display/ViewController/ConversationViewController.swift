//
//  ConversationViewController.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/1/24.
//

import UIKit

open class ConversationViewController: MessagesViewController, MessageCellDelegate , MessagesDataSource , MessagesLayoutDelegate , MessagesDisplayDelegate, ChatAudioRecordDelegate {
    
    open lazy var conversationInputBar: ConversationInputBar = { [unowned self] in
        $0.delegate = self
        $0.status = .normal
        $0.backgroundColor = UIColor(red: 250/255.0, green: 250/255.0, blue: 250/255.0, alpha: 1.0)
        return $0
    }(ConversationInputBar())
    
    //音频指示器
    open lazy var voiceIndicator: VoiceIndicatorView = {
        
        view.addSubview($0)
        
        $0.translatesAutoresizingMaskIntoConstraints = false
        
        var constraints: Array<NSLayoutConstraint> = Array<NSLayoutConstraint>()
        
        if #available(iOS 11.0, *) {
            constraints.append(NSLayoutConstraint(item: $0, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1.0, constant: 100))
            constraints.append(NSLayoutConstraint(item: $0, attribute: .bottom, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: -100))
            
        } else {
            constraints.append(NSLayoutConstraint(item: $0, attribute: .top, relatedBy: .equal, toItem: self.topLayoutGuide, attribute: .top, multiplier: 1.0, constant: 100))
            constraints.append(NSLayoutConstraint(item: $0, attribute: .bottom, relatedBy: .equal, toItem: self.bottomLayoutGuide, attribute: .bottom, multiplier: 1.0, constant: -100))
        }
        
        constraints.append(NSLayoutConstraint(item: $0, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1.0, constant: 0))
        constraints.append(NSLayoutConstraint(item: $0, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1.0, constant: 0))
        
        view.addConstraints(constraints)
        
        return $0
    }(VoiceIndicatorView())
    
    //音频输入类 因为子类重写需要调用, 这里放开作用域
    open lazy var soundRecorder: ChatSoundRecorder = ChatSoundRecorder(delegate: self)
    
    //播放管理类
    open lazy var chatAudioPlay = ChatAudioPlayManager()
    
    public let task: Task
    
    public init(task: Task) {
        self.task = task
        super.init(nibName: nil, bundle: nil)
    }
    
    /// 自定义底部工具栏
    open override var messageInputBar: MessageInputBar! {
        return conversationInputBar
    }
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        scrollsToBottomOnKeybordBeginsEditing = true
        maintainPositionOnKeyboardFrameChanged = true
        
        messagesCollection.messageDataSource = self
        messagesCollection.messagesLayoutDelegate = self
        messagesCollection.messagesDisplayDelegate = self
        messagesCollection.messageCellDelegate = self
        messagesCollection.setIndicatorHeader {
            //下拉加载更多消息
            self.loadMoreMessages()
        }
        
        messagesCollection.closeKeyboardCompletion = { [unowned self] in
            self.messageInputBar.inputTextView.resignFirstResponder()
        }
        
        //监听新消息过来
        task.listenerNewMessage(completion: { [weak self](receiveMsg) in
            //消息的监听回调可能不是当前会话的, 也会走进来, 所以为了
            self?.messagesCollection.reloadDataAndKeepOffset()
        })
        
        //已读回执,刷新tableView
        task.listenerUpdateReceiptMessages { [unowned self] in
            //因为可能好几条消息都未读, 这里只刷新一个item还不行, 要reloadData
            self.messagesCollection.reloadData()
        }
        
        loadMoreMessages()
    }
    
    open func loadMoreMessages() {
        
        //FIXME: - loadRecentMessages要在viewController销毁时, 置为nil, 否则会因为逃逸闭包, unowned修饰引起崩溃
        task.loadRecentMessages { [weak self] (result, isFirstLoadData) in
            
            guard let this = self else { return }
            
            switch result {
            case .success(let receiveMsg):
                
                guard receiveMsg.isEmpty == false else {
                    this.messagesCollection.endRefreshingAndNoMoreData()
                    return
                }
                
                if isFirstLoadData {
                    this.messagesCollection.reloadDataAndMoveToBottom()
                }
                else {
                    
                    //下拉加载资源时, 会导致selectedIndex索引位置改变, 需要手动更新一下
                    this.selectedIndexPath?.section += receiveMsg.count
                    
                    //1.刷新TableView
                    this.messagesCollection.reloadDataAndKeepOffset()
                    
                    //2.收起菊花, 如果没有更多数据, 就隐藏indicator
                    if receiveMsg.count <= this.task.loadMessageCount {
                        this.messagesCollection.endRefreshingAndNoMoreData()
                    }
                    else {
                        this.messagesCollection.endRefreshing()
                    }
                }
                
            case .failure:
                this.showToast(message: "数据拉取失败, 请退出重试")
                this.messagesCollection.endRefreshing()
            }
            
        }
        
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { _ in
            self.task.active()
        }
        
        NotificationCenter.default.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: nil) { _ in
            self.task.resign()
        }
        
    }
    
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        task.free()
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIApplication.willEnterForegroundNotification, object: nil)
    }
    
    //MARK: - MessageCellDelegate
    
    open func didTapMessage(in cell: MessageCollectionViewCell, message: MessageType) {
        
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
    
    open func controlBtnDidTapped(state: UIControl.State) {
        switch state {
        case .normal:
            break
        case .selected:
            //已切换到音频输入模式
            soundRecorder.checkIsVaildRecordIfNeeded()
        default:
            break
        }
    }
    
    /// 准备发送文本消息
    ///
    /// - Parameter text: 文本
    open func prepareSendMessage(text: String) {
        let message = MessageElem(text: text, sender: currentSender())
        onMessageWillSend(message)
        sendMsg(msg: message)
    }
    
    open func longPressVoiceAction(gesture: UIGestureRecognizer) {
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
    
    //MARK: - ChatAudioRecordDelegate
    
    open func audioRecordStateDidChange(_ status: ChatRecorderState) {
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
    
    open func audioRecordPeakDidChange(_ value: Int) {
        voiceIndicator.updateMetersValue(value - 1)
    }
    
    open func audioRecordFinish(_ uploadAmrData: Data, recordTime: TimeInterval) {
        //TODO: 替换最后一个消息, 发送消息
        let soundMsg = MessageElem(data: uploadAmrData, dur: Int32(recordTime), sender: currentSender())
        replaceLastMessage(newMsg: soundMsg)
        sendMsg(msg: soundMsg)
    }
    
    /// 请求录音权限失败的处理
    open func audioRecordRequestPermissionFailure() {
        let alertVC = UIAlertController(title: "\"\(Bundle.displayName)\"想访问您的麦克风", message: "只有打开麦克风,才可以发送语音哦~", preferredStyle: .alert)
        alertVC.addAction(UIAlertAction(title: "不允许", style: .cancel, handler: nil))
        alertVC.addAction(UIAlertAction(title: "好", style: .default, handler: { (action) in
            if let url = URL(string: UIApplication.openSettingsURLString) {
                UIApplication.shared.openURL(url)
            }
        }))
        present(alertVC, animated: true, completion: nil)
    }
    
    
    open func playAudio(message: MessageElem, result: @escaping (String?) -> Void) {
        
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
    
    //MARK: - MessagesDataSource
    
    open func isFromCurrentSender(message: MessageType) -> Bool {
        
        /*
         消息显示规则是: 先渲染到界面中, 然后在根据发送状态, 做后续处理, 如果发送未成功就将之前渲染的移除掉, 因为是先渲染的, 就会造成消息体自身sender对象为空, 所以这里判断为空, 表示由自己发出去的
         */
        
        if message.sender.id.isEmpty {
            return true
        }
        
        return currentSender() == message.sender
    }
    
    
    open func currentSender() -> Sender {
        return task.host
    }
    
    open func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return task.messagesList[indexPath.section]
    }
    
    open func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return task.messagesList.count
    }
    
    //MARK: - MessagesLayoutDelegate
    
    open func messageInsets(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        if isFromCurrentSender(message: message) {
            return UIEdgeInsets(top: 11, left: 12, bottom: 11, right: 14)
        }
        else {
            return UIEdgeInsets(top: 11, left: 14, bottom: 11, right: 12)
        }
    }
    
    final override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //避免消息过多，内存激增。
//        task.removeSubrange()
//        messagesCollection.reloadData()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open func showToast(message: String) {
        fatalError("子类必须实现")
    }
}

extension ConversationViewController: ConversationInputBarDelegate {

    public func inputBar(_ bar: ConversationInputBar, controlBtnDidTapped btn: UIButton) {
        controlBtnDidTapped(state: bar.status)
    }

    public func inputBar(_ bar: ConversationInputBar, senderBtnDidTapped btn: UIButton) {
        guard let text = bar.inputTextView.text, text.isEmpty == false else {
            showToast(message: "输入的内容不能为空")
            return
        }
        
        prepareSendMessage(text: text)
    }

    public func inputBar(_ bar: ConversationInputBar, recordBtnLongPressGesture gesture: UIGestureRecognizer) {
        longPressVoiceAction(gesture: gesture)
    }

}

extension ConversationViewController {
    
    public func onMessageCancelSend() {
        guard task.messagesList.isEmpty == false else { return }
        
        task.removeLast()
        //FIXME: - 不用刷新是否可行
        messagesCollection.deleteSections(task.messagesList.indexSet)

        if task.messagesList.isEmpty == false {
            messagesCollection.reloadDataAndKeepOffset()
        }
    }
    
    //已测试
    public func onMessageWillSend(_ message: MessageElem) {
        task.append(message)
        messagesCollection.insertSections(task.messagesList.indexSet)
        messagesCollection.scrollToBottom()
        messageInputBar.inputTextView.text = String()
    }
    
    public func replaceLastMessage(newMsg: MessageElem) {
        task.replaceLast(newMsg)
        messagesCollection.performBatchUpdates(nil)
        if task.messagesList.count >= 1 {
            messagesCollection.reloadDataAndKeepOffset()
        }
    }
    
    /// 发送消息
    ///
    /// - Parameter msg:
    public func sendMsg(msg: MessageElem) {
        
        //发送消息
        task.send(message: msg) { [weak self](result) in
            //FIXME: - code 值不对
            if case .failure(let error) = result, error == .unsafe {
                self?.showToast(message: "请不要发送敏感词汇")
                self?.onMessageCancelSend()
                return
            }
            
            guard let section = self?.task.messagesList.index(of: msg) else { return }
            self?.messagesCollection.reloadSections([section])
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

