//
//  IMChatViewController+interaction.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import Foundation
import TSVoiceConverter
import Kingfisher

extension IMChatViewController: IMChatCellEventDelegate {

    func cellDidTaped(_ cell: IMBaseCell) {
        
    }
    
    /**
     点击了 cell 的头像
     */
    func cellDidTapedAvatarImage(_ cell: IMBaseCell) {
        
    }
    
    /**
     点击了 cell 的图片
     */
    func cellDidTapedImageView(_ cell: IMBaseCell) {
        
    }
    
    /**
     点击了 cell 中文字的 URL
     */
    func cellDidTapedLink(_ cell: IMBaseCell, linkString: String) {
        
    }
    
    /**
     点击了 cell 中文字的 电话
     */
    func cellDidTapedPhone(_ cell: IMBaseCell, phoneString: String) {
        
    }
    
    func cellDidTapedRetry(msg: IMMessage?) {
        guard let msg = msg else {
            return
        }
        dispatch_async_safely_to_main_queue { [weak self] in
            self?.retrySendMsg(msg: msg)
        }
    }
    
    /**
     点击了声音 cell 的播放 button
     */
    func cellDidTapedVoiceButton(_ cell: IMAudioCell, isPlayingVoice: Bool) {
        if voicePlayingCell != nil && voicePlayingCell != cell {
            voicePlayingCell?.stopPlayVoice()
            chatAudioPlay.stopPlay()
        }
        if isPlayingVoice {
            voicePlayingCell = cell
            
            cell.msgModel?.getSoundPath(succ: { [weak self](url) in
                
                guard let unwrappedURL = url else {
                    self?.voicePlayingCell?.stopPlayVoice()
                    return
                }
                
                self?.chatAudioPlay.playWith(url: unwrappedURL, finish: { [weak self] in
                    self?.voicePlayingCell?.stopPlayVoice()
                })
                
            }, fail: { [weak self] (code, str) in
                dispatch_async_safely_to_main_queue { [weak self] in
                    self?.showToast(message:"播放语音消息失败\(String(describing: str))")
                }
                self?.voicePlayingCell?.stopPlayVoice()
            })
            
        }else{
            chatAudioPlay.stopPlay()
        }
    }
    
}
