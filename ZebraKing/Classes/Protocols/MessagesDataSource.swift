//
//  MessagesDataSource.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/6.
//

import Foundation

public protocol MessagesDataSource: AnyObject {

    func currentSender() -> Sender
    
    func isFromCurrentSender(message: MessageType) -> Bool
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType
    
    func numberOfMessages(in messagesCollectionView: MessagesCollectionView) -> Int
    
}
