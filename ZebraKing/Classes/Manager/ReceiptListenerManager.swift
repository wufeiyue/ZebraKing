//
//  ReceiptListenerManager.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/30.
//  消息监听

import Foundation
import ImSDK

class ReceiptListener: NSObject {
    
    var currentReceiver: String {
        return conversation.getReceiver()
    }
    
    var updateReceiveMessagesCompletion: ((TIMMessage) -> Void)?
    
    var conversation: IMConversation
    
    init(conversation: IMConversation) {
        self.conversation = conversation
        super.init()
        TIMManager.sharedInstance().getUserConfig().receiptListener = self
    }
    
    func removeListener() {
        TIMManager.sharedInstance().getUserConfig().receiptListener = nil
//        updateReceiveMessagesCompletion = nil
    }
    
}

extension ReceiptListener: TIMMessageReceiptListener {
    
    //对方在调用setMessageRead方法时,就会走这个回调(已读回执)
    public func onRecvMessageReceipts(_ receipts: [Any]!) {
        
        guard let list = receipts as? Array<TIMMessageReceipt> else { return }
        
        for receipt in list {
            if receipt.conversation.getReceiver() == currentReceiver {
                
                //最后一条消息为已读状态,就直接跳过处理
                let lastMsgs = receipt.conversation.getLastMsgs(1) as! [TIMMessage]
                guard let lastMessage = lastMsgs.first else { return }
                
                if lastMessage.isSelf() && lastMessage.isPeerReaded(){
                    conversation.alreadyRead(message: lastMessage)
                    self.updateReceiveMessagesCompletion?(lastMessage)
                }
            }
            else {
                self.updateReceiveMessagesCompletion = nil
            }
        }
        
    }
    
}
