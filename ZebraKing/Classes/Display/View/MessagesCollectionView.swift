//
//  MessagesCollectionView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/1/24.
//

import UIKit
import Kingfisher

public typealias MessageID = String

open class MessagesCollectionView: UICollectionView {
    
    open weak var messageDataSource: MessagesDataSource?
    
    open weak var messagesLayoutDelegate: MessagesLayoutDelegate?
    
    open weak var messagesDisplayDelegate: MessagesDisplayDelegate?
    
    open weak var messageCellDelegate: MessageCellDelegate?
    
    public override init(frame: CGRect, collectionViewLayout layout: UICollectionViewLayout) {
        super.init(frame: frame, collectionViewLayout: layout)
        backgroundColor = .white
        setupGestureRecognizers()
    }
    
    public convenience init() {
        self.init(frame: .zero, collectionViewLayout: MessagesCollectionViewFlowLayout())
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupGestureRecognizers() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGesture.delaysTouchesBegan = true
        addGestureRecognizer(tapGesture)
    }
    
    @objc
    open func handleTapGesture(_ gesture: UIGestureRecognizer) {
        guard gesture.state == .ended else { return }
        
        let touchLocation = gesture.location(in: self)
        guard let indexPath = indexPathForItem(at: touchLocation) else { return }
        
        let cell = cellForItem(at: indexPath) as? MessageCollectionViewCell
        cell?.handleTapGesture(gesture)
    }
    
    public func scrollToBottom(animated: Bool = false) {
        let collectionViewContentHeight = collectionViewLayout.collectionViewContentSize.height
        
        guard collectionViewContentHeight > 0 else {
            return
        }
        
        performBatchUpdates(nil) { _ in
            self.scrollRectToVisible(CGRect(x: 0.0, y: collectionViewContentHeight - 1.0, width: 1.0, height: 1.0), animated: animated)
        }
        
    }
    
    //数据加载并保持位置不变
    public func reloadDataAndKeepOffset() {
        //停止滑动
        setContentOffset(contentOffset, animated: false)
        
        let beforeCOntentSize = contentSize
        reloadData()
        layoutIfNeeded()
        let afterContentSize = contentSize
        
        let newOffset = CGPoint(
            x: contentOffset.x + (afterContentSize.width - beforeCOntentSize.width),
            y: contentOffset.y + (afterContentSize.height - beforeCOntentSize.height))
        setContentOffset(newOffset, animated: false)
    }
    
    //数据加载并移至最底部
    public func reloadDataAndMoveToBottom() {
        
        reloadData()
        
        let collectionViewContentHeight = collectionViewLayout.collectionViewContentSize.height
        
        guard collectionViewContentHeight > 0 else {
            return
        }
        
        let newOffset = CGPoint(x: contentOffset.x, y: contentOffset.y + collectionViewContentHeight)
        setContentOffset(newOffset, animated: false)
        
    }
}
