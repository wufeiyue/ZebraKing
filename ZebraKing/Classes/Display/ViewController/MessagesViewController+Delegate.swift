//
//  MessagesViewController+Delegate.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/6.
//

import UIKit

extension MessagesViewController: UICollectionViewDelegateFlowLayout {
    
    public func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        guard let messageFlowLayout = collectionViewLayout as? MessagesCollectionViewFlowLayout else { return .zero }
        return messageFlowLayout.sizeForItem(at: indexPath)
    }
    
    //MARK: - 复制文本
    public func collectionView(_ collectionView: UICollectionView, shouldShowMenuForItemAt indexPath: IndexPath) -> Bool {
        guard let messagesDataSource = messagesCollection.messageDataSource else { return false }
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollection)
        
        switch message.data {
        case .text, .attributedText, .emoji, .photo:
            selectedIndexPathForMenu = indexPath
            return true
        default:
            return false
        }
    }
    
    public func collectionView(_ collectionView: UICollectionView, canPerformAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) -> Bool {
        return (action == NSSelectorFromString("copy:"))
    }
    
    public func collectionView(_ collectionView: UICollectionView, performAction action: Selector, forItemAt indexPath: IndexPath, withSender sender: Any?) {
        guard let messagesDataSource = messagesCollection.messageDataSource else { return }
        let pasteBoard = UIPasteboard.general
        let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollection)
        
        switch message.data {
        case .text(let text), .emoji(let text):
            pasteBoard.string = text
        case .attributedText(let attr):
            pasteBoard.string = attr.string
        case .photo(let image):
            pasteBoard.image = image
        default:
            break
        }
    }
    
}

