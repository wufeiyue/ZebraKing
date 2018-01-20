//
//  IMChatViewController.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
// 会话界面
//

import UIKit
import SnapKit
import MJRefresh
import BMKP_Network

public protocol IMChattingDelegate: class {
    var receiver:IMUserUnit { set get }
    var chatTitle: String? { set get }
}

public protocol IMChatViewControllerDelegate: class {
    //在第一次加载数据为空的时候,去请求网络数据(一般在与客服聊天的时候, 进来客服先说话)
    func chatViewController(_ viewController: IMChatViewController, firstRequestNetworkDidLoadData receiver: IMUserUnit) -> DefaultRequest?
}

open class IMChatViewController: UIViewController, IMChattingDelegate {
    
    public weak var delegate: IMChatViewControllerDelegate?
    public var voiceIndicatorView: IMVoiceIndicator? //录音的时候的指示View
    public var voicePlayingCell: IMAudioCell? //正在播放声音的cell
    public var conversation: IMConversation?
    public var receiver:IMUserUnit = .server //会话的对象
    public var chatTitle: String?
    public var tableView: UITableView!
    public var chatActionBarView: IMChatActionBar!
    internal var messageList = IMMessageList()  //消息列表
    
    //录音管理类
    lazy var soundRecorder: IMChatSoundRecorder = { [unowned self] in
        let recorder = IMChatSoundRecorder()
        recorder.delegate = self
        return recorder
    }()
    
    //播放管理类
    lazy var chatAudioPlay = IMChatAudioPlayManager()
    
    public lazy var sentenceContainerView: IMDriverSentenceContainerView = { [unowned self] in
        let view = IMDriverSentenceContainerView(frame: self.view.bounds, type: receiver.role)
        view.delegate = self
        return view
    }()
    
    public lazy var header: MJRefreshHeader = {
        let header = MJRefreshNormalHeader()
        header.setRefreshingTarget(self, refreshingAction: #selector(onRefresh))
        header.isAutomaticallyChangeAlpha = true
        header.lastUpdatedTimeLabel.isHidden = true
        header.stateLabel.isHidden = true
        header.mj_h = 30
        return header
    }()
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        addTableView()
        addChatActionBarView()
        initData()
        
        view.backgroundColor = UIColor(hexString: "#F2F2F2")
        navigationController?.view.addSubview(sentenceContainerView)
        
    }
    
    open override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        keyboardControl()
        setViewTitle()
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
        
        soundRecorder.recordPeak.bindListener(key: "recordPeak", action: { [weak self](meter) in
            DispatchQueue.main.async { [weak self] in
                self?.voiceIndicatorView?.updateMetersValue(meter - 1)
            }
        })
        
        soundRecorder.recordState.bindListener(key: "recordState", action: { [weak self](state) in
            DispatchQueue.main.async { [weak self] in
                self?.audioRecordStateChanged(state)
            }
        })
        
        soundRecorder.requestRecordPermissionFailure = { [weak self] in
            let alertVC = UIAlertController(title: "\"\(Bundle.displayName)\"想访问您的麦克风", message: "只有打开麦克风,才可以发送语音哦~", preferredStyle: .alert)
            alertVC.addAction(UIAlertAction(title: "不允许", style: .cancel, handler: nil))
            alertVC.addAction(UIAlertAction(title: "好", style: .default, handler: { (action) in
                if let url = URL(string: UIApplicationOpenSettingsURLString) {
                    UIApplication.shared.openURL(url)
                }
            }))
            self?.present(alertVC, animated: true, completion: nil)
        }
    }
    
    @objc
    private func applicationWillEnterForeground() {
        soundRecorder.setNeedCheckIsVaildRecord()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if self.receiver.role == .server {
            // 去掉tabbar小红点
//            self.tabBarController?.bk.messageDot(at: 2, isShow: false)
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        chatAudioPlay.stopPlay()
        
        IMChatManager.default.releaseConversation()
        
        hideKeyBoard()
        NotificationCenter.default.removeObserver(self, name: .UIApplicationWillEnterForeground, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
        
        soundRecorder.recordPeak.removeListener(key: "recordPeak")
        soundRecorder.recordState.removeListener(key: "recordState")
    }
    
    private func addTableView() {
        tableView = UITableView(frame: .zero, style: .plain)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.scrollsToTop = true
        tableView.separatorInset = .zero
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor(hexString: "#F2F2F2")
        tableView.tableFooterView = UIView(frame: .zero)
        tableView.register(IMTextCell.self, forCellReuseIdentifier: "IMTextCellKey")
        tableView.register(IMAudioCell.self, forCellReuseIdentifier: "IMAudioCellKey")
        tableView.register(IMTimeTipCell.self, forCellReuseIdentifier: "IMTimeTipCellKey")
        tableView.estimatedRowHeight = 55
        tableView.mj_header = self.header
        let tap = UITapGestureRecognizer(target: self, action: #selector(hideKeyBoard))
        tableView.addGestureRecognizer(tap)
        view.addSubview(tableView)
        tableView.snp.makeConstraints { (m) in
            if #available(iOS 11.0, *) {
                m.top.equalTo(self.view.safeAreaLayoutGuide.snp.top)
            } else {
                m.top.equalTo(self.topLayoutGuide.snp.bottom)
            }
            m.left.right.equalToSuperview()
        }
    }
    
    private func addChatActionBarView() {
        
        chatActionBarView = IMChatActionBar(type: receiver.role.actionBarType)
        chatActionBarView.backgroundColor = UIColor(hexString: "#FCFCFC")
        chatActionBarView.delegate = self
        view.addSubview(chatActionBarView)
        chatActionBarView.snp.makeConstraints { (m) in
            m.left.right.equalToSuperview()
            m.top.equalTo(tableView.snp.bottom)
            if #available(iOS 11.0, *) {
                m.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            } else {
                m.bottom.equalTo(self.bottomLayoutGuide.snp.top)
            }
        }
        
    }
    
    private func initData() {
        
        //开始聊天
        conversation = IMChatManager.default.chat(with: receiver.chatModel)
        
        //监听新消息过来
        conversation?.listenerNewMessage(msgList: { [weak self](data) in
            dispatch_async_safely_to_main_queue {
                self?.onReceiveNewMsg(msgList: data)
                self?.clearMemory(maxCount: 200, cutCount: 20)
            }
        })
        
        //已读回执,刷新tableView
        conversation?.listenerUpdateReceiptMessages { [weak self] in
            self?.tableView.reloadData()
        }
        
        let loadCompletion: LoadResultCompletion = { [weak self] (result) in
            switch result {
            case .success(let receiveMsg):
                if receiveMsg.isEmpty {
                    self?.sendRequest()
                    return
                }
                self?.onReceiveNewMsg(msgList: receiveMsg)
                self?.clearMemory(maxCount: 200, cutCount: 20)
            case .failure:
                break
            }
            
        }
        conversation?.loadRecentMessages(count: 20, completion: loadCompletion)
    }
    
    @objc
    func onRefresh() {
        let refreshCompletion: LoadResultCompletion = { [weak self] (result) in
            switch result {
            case .success(let receiveMsg):
                self?.onLoadRefreshMessage(msgList: receiveMsg)
            case .failure:
                break
            }
            self?.tableView.mj_header.endRefreshing()
        }
        conversation?.loadRecentMessages(count: 10, completion: refreshCompletion)
    }
    
    /// 设置VC聊天对象的title
    ///
    /// - Parameter title: title对外参数
    private func setViewTitle() {
        
        var name: String = receiver.name
        
        if let chatTitle = chatTitle {
            name = chatTitle
        }
        
        if name.count > 10 {
            let idx = name.index(name.startIndex, offsetBy: 10)
            name = String(name[..<idx])
        }
        self.title = name
    }
 
    private func sendRequest() {
        if let request = delegate?.chatViewController(self, firstRequestNetworkDidLoadData: receiver) {
            request.send().failure({ [weak self](error) in
                self?.showToast(message: error.localizedDescription)
            })
        }
    }
 
    open func showToast(message: String) {}
}

extension IMChatViewController:UITableViewDelegate, UITableViewDataSource {

    //cell高度
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if let type = messageList[indexPath.row].type {
            return type.chatCellHeight(messageList[indexPath.row])
        } else {
            return 0
        }
    }
    
    //每组个数
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messageList.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let type = messageList[indexPath.row].type {
            let cell = type.chatCell(tableView, indexPath: indexPath, model: messageList[indexPath.row], receiver: receiver, viewController: self)
             return cell
        }else {
            return UITableViewCell()
        }
    }

}

extension IMChatViewController: UIScrollViewDelegate {
    //开始拖动列表，隐藏键盘
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.hideKeyBoard()
    }

}

