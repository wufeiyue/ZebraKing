//
//  MessagesViewController+Menu.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/7/10.
//

import Foundation

extension MessagesViewController {
    
    func addMenuControllerObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(MessagesViewController.menuControllerWillShow(_:)), name: .UIMenuControllerWillShowMenu, object: nil)
    }
    
    func removeMenuControllerObservers() {
        NotificationCenter.default.removeObserver(self, name: .UIMenuControllerWillShowMenu, object: nil)
    }
    
    @objc
    func menuControllerWillShow(_ notification: Notification) {
        
        guard let currentMenuController = notification.object as? UIMenuController,
            let selectedIndexPath = selectedIndexPathForMenu else { return }
        
        NotificationCenter.default.removeObserver(self, name: .UIMenuControllerWillShowMenu, object: nil)
        defer {
            NotificationCenter.default.addObserver(self,
                                                   selector: #selector(MessagesViewController.menuControllerWillShow(_:)),
                                                   name: .UIMenuControllerWillShowMenu, object: nil)
            selectedIndexPathForMenu = nil
        }
        
        currentMenuController.setMenuVisible(false, animated: false)
        
        guard let selectedCell = messagesCollection.cellForItem(at: selectedIndexPath) as? MessageCollectionViewCell else { return }
        let selectedCellMessageBubbleFrame = selectedCell.convert(selectedCell.messageContainerView.frame, to: view)
        
        var messageInputBarFrame: CGRect = .zero
        if let messageInputBarSuperview = messageInputBar.superview {
            messageInputBarFrame = view.convert(messageInputBar.frame, from: messageInputBarSuperview)
        }
        
        var topNavigationBarFrame: CGRect = navigationBarFrame
        if navigationBarFrame != .zero, let navigationBarSuperview = navigationController?.navigationBar.superview {
            topNavigationBarFrame = view.convert(navigationController!.navigationBar.frame, from: navigationBarSuperview)
        }
        
        let menuHeight = currentMenuController.menuFrame.height
        
        let selectedCellMessageBubblePlusMenuFrame = CGRect(x: selectedCellMessageBubbleFrame.origin.x,
                                                            y: selectedCellMessageBubbleFrame.origin.y - menuHeight,
                                                            width: selectedCellMessageBubbleFrame.size.width,
                                                            height: selectedCellMessageBubbleFrame.size.height + 2 * menuHeight)
        
        var targetRect: CGRect = selectedCellMessageBubbleFrame
        currentMenuController.arrowDirection = .default
        
        if selectedCellMessageBubblePlusMenuFrame.intersects(topNavigationBarFrame) && selectedCellMessageBubblePlusMenuFrame.intersects(messageInputBarFrame) {
            let centerY = (selectedCellMessageBubblePlusMenuFrame.intersection(messageInputBarFrame).minY + selectedCellMessageBubblePlusMenuFrame.intersection(topNavigationBarFrame).maxY) / 2
            targetRect = CGRect(x: selectedCellMessageBubblePlusMenuFrame.midX, y: centerY, width: 1, height: 1)
        }
        else if selectedCellMessageBubblePlusMenuFrame.intersects(topNavigationBarFrame) {
            currentMenuController.arrowDirection = .up
        }
        
        currentMenuController.setTargetRect(targetRect, in: view)
        
        currentMenuController.setMenuVisible(true, animated: true)
        
    }
    
    private var navigationBarFrame: CGRect {
        guard let navigationController = navigationController, !navigationController.navigationBar.isHidden else {
            return .zero
        }
        return navigationController.navigationBar.frame
    }
}
