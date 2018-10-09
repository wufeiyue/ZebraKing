//
//  ConversationViewController.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/1/24.
//

import UIKit

open class ConversationViewController: MessagesViewController, MessageCellDelegate, Toastable {

    public let conversation: Conversation
    
    //FIXME: - 替换成 MessagesList<IMMessage>()
    public var messagesList = IMMessageList()  //消息列表
    
    public init(conversation: Conversation) {
        self.conversation = conversation
        super.init(nibName: nil, bundle: nil)
    }
    
    public required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
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
        
        //监听新消息过来
        conversation.listenerNewMessage(msgList: { [unowned self](receiveMsg) in
            self.messagesList.addList(newsList: receiveMsg)
            self.messagesCollection.reloadDataAndKeepOffset()
        })
        
        //已读回执,刷新tableView
        conversation.listenerUpdateReceiptMessages { [unowned self] in
            self.messagesCollection.reloadData()
        }
        
        let loadCompletion: LoadResultCompletion = { [unowned self] (result) in
            
            switch result {
            case .success(let receiveMsg):
                
                guard receiveMsg.isEmpty == false else { return }
                
                self.messagesList.addList(newsList: receiveMsg)
                self.messagesCollection.reloadData()
                self.messagesCollection.scrollToBottom()
                
            case .failure:
                self.showToast(message: "数据拉取失败, 请退出重试")
                break
            }
        }
        
        //FIXME: - loadRecentMessages要在viewController销毁时, 置为nil, 否则会因为逃逸闭包, unowned修饰引起崩溃
        conversation.loadRecentMessages(count: 20, completion: loadCompletion)
    }
    
    @objc
    func loadMoreMessages() {
        
        let count: Int = 20
        
        let refreshCompletion: LoadResultCompletion = { [weak self] (result) in
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: {
                
                switch result {
                case .success(let receiveMsg):
                    
                    guard receiveMsg.isEmpty == false else {
                        self?.messagesCollection.endRefreshingAndNoMoreData()
                        return
                    }
                    
                    //1.插入数据
                    self?.messagesList.inset(newsList: receiveMsg)
                    //下拉加载资源时, 会导致selectedIndex索引位置改变, 需要手动更新一下
                    self?.selectedIndexPath?.section += receiveMsg.count
                    
                    //2.刷新TableView
                    self?.messagesCollection.reloadDataAndKeepOffset()
                    
                    //3.收起菊花, 如果没有更多数据, 就隐藏indicator
                    if receiveMsg.count <= count {
                        self?.messagesCollection.endRefreshingAndNoMoreData()
                    }
                    else {
                        self?.messagesCollection.endRefreshing()
                    }
                    
                case .failure:
                    self?.showToast(message: "数据拉取失败, 请退出重试")
                    self?.messagesCollection.endRefreshing()
                }
                
            })
        }
        
        //FIXME: - loadRecentMessages要在viewController销毁时, 置为nil, 否则会因为逃逸闭包, unowned修饰引起崩溃
        conversation.loadRecentMessages(count: count, completion: refreshCompletion)
    }
    
    //FIXME: - 后期要后话, conversation自己控制生命周期
    open override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        conversation.releaseSelf()
    }

    final override public func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        //避免消息过多，内存激增。
        messagesList.removeSubrange(num: 20)
        messagesCollection.reloadData()
    }
    
    public func didTapMessage(in cell: MessageCollectionViewCell, message: MessageType) { }
    
    public func didContainer(in cell: MessageCollectionViewCell, message: MessageType) { }
}

extension ConversationViewController: MessagesDataSource {
    
    public func isFromCurrentSender(message: MessageType) -> Bool {
        
        /*
         消息显示规则是: 先渲染到界面中, 然后在根据发送状态, 做后续处理, 如果发送未成功就将之前渲染的移除掉, 因为是先渲染的, 就会造成消息体自身sender对象为空, 所以这里判断为空, 表示由自己发出去的
         */
        
        if message.sender.id.isEmpty {
            return true
        }
        
        return currentSender() == message.sender
    }
    
    
    public func currentSender() -> Sender {
        return conversation.host
    }
    
    public func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messagesList[indexPath.section]
    }
    
    public func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messagesList.count
    }
    
}

extension ConversationViewController: MessagesLayoutDelegate {
    
    public func avatarSize(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGSize {
        return CGSize(width: 42, height: 42)
    }
    
    public func messagePadding(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        return UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
    }
    
    public func messageInsets(at indexPath: IndexPath, message: MessageType, in messagesCollectionView: MessagesCollectionView) -> UIEdgeInsets {
        if isFromCurrentSender(message: message) {
            return UIEdgeInsets(top: 11, left: 12, bottom: 11, right: 14)
        }
        else {
            return UIEdgeInsets(top: 11, left: 14, bottom: 11, right: 12)
        }
    }
}

extension ConversationViewController: MessagesDisplayDelegate {
    
    public func readStatus(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> Bool {
        return true
    }
    
    public func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .date]
    }
    
    public func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key : Any] {
        return MessageLabel.defaultAttributes
    }
}

extension ConversationViewController {
    
    func onMessageCancelSend() {
        guard messagesList.isEmpty == false else { return }
        
        messagesList.removeLast()
        //FIXME: - 不用刷新是否可行
        messagesCollection.deleteSections(messagesList.indexSet)

        if messagesList.isEmpty == false {
            messagesCollection.reloadDataAndKeepOffset()
        }
    }
    
    //已测试
    func onMessageWillSend(_ message: IMMessage) {
        messagesList.append(message)
        messagesCollection.insertSections(messagesList.indexSet)
        messagesCollection.scrollToBottom()
        messageInputBar.inputTextView.text = String()
    }
    
    func replaceLastMessage(newMsg: IMMessage) {
        messagesList.replaceLast(newMsg)
        messagesCollection.performBatchUpdates(nil)
        if messagesList.count >= 1 {
            messagesCollection.reloadDataAndKeepOffset()
        }
    }
    
    /// 发送消息
    ///
    /// - Parameter msg:
    func sendMsg(msg: IMMessage) {
        
        //发送消息
        conversation.send(message: msg) { [weak self](result) in
            
            if case .failure(let error) = result, error.code == 80001 {
                self?.showToast(message: "请不要发送敏感词汇")
                self?.onMessageCancelSend()
                return
            }
            
            guard let section = self?.messagesList.index(of: msg) else { return }
            self?.messagesCollection.reloadSections([section])
        }
        
    }
}

