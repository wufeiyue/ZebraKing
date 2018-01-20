//
//  IMChatCellEventDelegate.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import Foundation


@objc protocol IMChatCellEventDelegate: class {
    /**
     点击了 cell 本身
     */
    @objc optional func cellDidTaped(_ cell: IMBaseCell)
    
    /**
     点击了 cell 的头像
     */
    func cellDidTapedAvatarImage(_ cell: IMBaseCell)
    
    /**
     点击了 cell 的图片
     */
    func cellDidTapedImageView(_ cell: IMBaseCell)
    
    /**
     点击了 cell 中文字的 URL
     */
    func cellDidTapedLink(_ cell: IMBaseCell, linkString: String)
    
    /**
     点击了 cell 中文字的 电话
     */
    func cellDidTapedPhone(_ cell: IMBaseCell, phoneString: String)
    
    /**
     点击了声音 cell 的播放 button
     */
    func cellDidTapedVoiceButton(_ cell: IMAudioCell, isPlayingVoice: Bool)
    
    /**
     重新发送这条消息
     */
    func cellDidTapedRetry(msg: IMMessage?)

}
