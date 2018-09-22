//
//  MessagesViewController+DataSource.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/6.
//

import UIKit

extension MessagesViewController: UICollectionViewDataSource {
    
    public func numberOfSections(in collectionView: UICollectionView) -> Int {
        guard let collectionView = collectionView as? MessagesCollectionView else {
            return 0
        }
        return collectionView.messageDataSource?.numberOfMessages(in: collectionView) ?? 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        guard let collectionView = collectionView as? MessagesCollectionView else {
            return 0
        }
        let messageCount = collectionView.messageDataSource?.numberOfMessages(in: collectionView) ?? 0
        return messageCount > 0 ? 1 : 0
    }
    
    open func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let messageCollectionView = collectionView as? MessagesCollectionView else { fatalError("仅支持使用MessageCollectionView") }
        
        guard let messageDataSource = messageCollectionView.messageDataSource else { fatalError("messageDataSource不能为空, 协议必须实现") }
        
        let messageType = messageDataSource.messageForItem(at: indexPath, in: messageCollectionView)
        
        switch messageType.data {
        case .text, .attributedText, .emoji:
            let cell = messageCollectionView.dequeueReusableCell(withReuseIdentifier: "TextMessageCellKey", for: indexPath) as! TextMessageCell
            cell.configure(with: messageType, at: indexPath, and: messageCollectionView)
            return cell
        case .photo, .video:
            let cell = messageCollectionView.dequeueReusableCell(withReuseIdentifier: "MediaMessageCellKey", for: indexPath) as! MediaMessageCell
            return cell
        case .location:
            let cell = messageCollectionView.dequeueReusableCell(withReuseIdentifier: "LocationMessageCellKey", for: indexPath) as! LocationMessageCell
            return cell
        case .audio:
            let cell = messageCollectionView.dequeueReusableCell(withReuseIdentifier: "AudioMessageCellKey", for: indexPath) as! AudioMessageCell
            cell.configure(with: messageType, at: indexPath, and: messageCollectionView)
            return cell
        case .timestamp:
            let cell = messageCollectionView.dequeueReusableCell(withReuseIdentifier: "TimestampCellKey", for: indexPath) as! TimestampCell
            cell.configure(with: messageType, at: indexPath, and: messageCollectionView)
            return cell
        case .custom(_):
            //FIXME: - custom
            let cell = messageCollectionView.dequeueReusableCell(withReuseIdentifier: "UICollectionViewCellKey", for: indexPath)
            return cell
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        
        guard let messageCollectionView = collectionView as? MessagesCollectionView else { fatalError("仅支持使用MessageCollectionView") }
        
        guard let messageDataSource = messageCollectionView.messageDataSource else { fatalError("messageDataSource不能为空, 协议必须实现") }
        
        let messageType = messageDataSource.messageForItem(at: indexPath, in: messageCollectionView)
        
        switch messageType.data {
        case .audio:
            let cell = cell as? AudioMessageCell
            if selectedIndexPath == indexPath {
                cell?.selectedAudio()
            }
            else {
                cell?.normalAudio()
            }
        default:
            break
        }
        
    }
}
