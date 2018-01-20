//
//  IMChatViewController+Handle.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import Foundation
import DynamicColor

extension IMChatViewController {
  
    /// 将拉取的消息插入到tabbleView中
    func onLoadRefreshMessage(msgList: [IMMessage]) {
        if msgList.count == 0 { return }
        messageList.inset(newsList: msgList)
        tableView.reloadData()
//        if msgList.count > 0 {
//            tableView.scrollToRow(at: IndexPath(item: msgList.count - 1, section: 0), at: .top, animated: false)
//        }
    }
 
    /// 接收到新的消息时触发的UI逻辑
    func onReceiveNewMsg(msgList: [IMMessage]) {
        messageList.addList(newsList: msgList)
        tableView.reloadData()
        if messageList.count > 0 {
            tableView.scrollToRow(at: IndexPath.init(row: messageList.count - 1, section: 0), at: .bottom, animated: false)
        }
    }
    
    
    /**
       避免消息过多，内存激增。
       maxCount: 消息数阈值，超过开始移除
       cutCount: 需要移除的数目  要小于阈值
     */
    func clearMemory(maxCount: Int, cutCount: Int) {
        var cutNum = cutCount
        if maxCount < cutCount { cutNum = maxCount }
        if messageList.count > maxCount  {
            messageList.removeSubrange(num: cutNum)
            tableView.reloadData()
        }
    }
    
    
    /**
     发送消息
     */
    func sendMsg(msg: IMMessage) {
        if messageList.count >= 1 {
            tableView.reloadRows(at: [IndexPath(row: messageList.count - 1, section: 0)], with: .none)
        }

        //发送消息
        conversation?.send(message: msg) { [weak self](result) in
            dispatch_async_safely_to_main_queue {
                switch result {
                case .success:
                    break
                case .failure(let error):
                    if error.code == 80001 {
                        self?.showToast(message:"请不要发送敏感词汇")
                        self?.onMessageCancelSend()
                        return
                    }
                }
                guard let row = self?.messageList.index(of: msg) else { return }
                self?.tableView.reloadRows(at: [IndexPath(row: row, section: 0)], with: .none)
            }
        }
        
    }
    
    /**
     准备发送消息
     */
    func onMessageWillSend(msg: IMMessage) {
        messageList.append(msg)
        tableView.beginUpdates()
        tableView.insertRows(at: messageList.indexRows, with: .none)
        tableView.endUpdates()
        tableView.scrollToRow(at: IndexPath(row: messageList.count - 1, section: 0), at: .bottom, animated: false)
    }

    /**
     使用新消息替代原来消息
     */
    func replaceLastMessage(newMsg: IMMessage) {
        messageList.replace(newMsg)
        tableView.beginUpdates()
        tableView.endUpdates()
        if messageList.count >= 1 {
            tableView.scrollToRow(at: IndexPath.init(row: messageList.count - 1, section: 0), at: .bottom, animated: false)
        }
    }

    /**
     取消即将发送的消息
     */
    func onMessageCancelSend() {
        
        guard messageList.isEmpty == false else {
            return
        }
        
        messageList.removeLast()
        tableView.beginUpdates()
        tableView.deleteRows(at: messageList.indexRows, with: .none)
        tableView.endUpdates()
        
        if messageList.isEmpty == false {
            tableView.scrollToRow(at: IndexPath(row: messageList.count - 1, section: 0), at: .bottom, animated: false)
        }
        
    }
    
    //FIXME: - 未测试
    func retrySendMsg(msg:IMMessage) {
        let index = messageList.index(of: msg)
        guard let lastIndex = index else {
            return
        }
        tableView.beginUpdates()
        messageList.removeLast()
        tableView.deleteRows(at: [IndexPath.init(row: lastIndex, section: 0)], with: .none)
        messageList.append(msg)
        tableView.insertRows(at: [IndexPath.init(row: messageList.count - 1, section: 0)], with: .none)
        tableView.endUpdates()
        sendMsg(msg: msg)
    }
    
}
