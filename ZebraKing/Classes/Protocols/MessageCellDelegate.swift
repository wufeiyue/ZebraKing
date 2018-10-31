//
//  MessageCellDelegate.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/27.
//

import Foundation

public protocol MessageCellDelegate: MessageLabelDelegate {
    
    //点击消息
    func didTapMessage(in cell: MessageCollectionViewCell, message: MessageType)
    
    //点击头像
    func didTapAvatar(in cell: MessageCollectionViewCell, message: MessageType)
    
    //点击附件
    func didTapAttachment(in cell: MessageCollectionViewCell, message: MessageType)
    
    //点击容器(会和别的代理一起触发)
    func didContainer(in cell: MessageCollectionViewCell, message: MessageType)
    
}

extension MessageCellDelegate {
    
    public func didTapAvatar(in cell: MessageCollectionViewCell, message: MessageType) {}
    
    public func didTapAttachment(in cell: MessageCollectionViewCell, message: MessageType) {}
    
    public func didContainer(in cell: MessageCollectionViewCell, message: MessageType) { }
    
    public func didTapMessage(in cell: MessageCollectionViewCell, message: MessageType) { }
}
