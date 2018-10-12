//
//  MessageStyle.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/8.
//

import UIKit

public enum MessageStyle: String {
    
    /// 键盘
    case keyboard
    
    /// 录音太短
    case messageTooShort
    
    /// 麦克风
    case microphone
    
    /// 取消录音
    case recordCancel
    
    /// 录音中的话筒
    case recordingBkg
    
    /// 音量
    case recordingSignal
    
    /// 重试
    case retry
    
    /// 对方语音播放默认提示
    case soundwave_b_n
    
    /// 对方语音播放选中提示
    case soundwave_b_s
    
    /// 我的语音播放默认提示
    case soundwave_w_n
    
    /// 我的语音播放选中提示
    case soundwave_w_s
    
    /// 我的消息背景
    case text_area_blue
    
    /// 对方消息背景
    case text_area_white
    
    /// 默认头像
    case avatar
    
    public var image: UIImage? {
        
        guard let path = imagePath() else { return nil }
        
        guard var image = UIImage(contentsOfFile: path) else { return nil }
        
        switch self {
        case .text_area_blue, .text_area_white:
            image = stretch(image)
        default:
            break
        }
        
        return image
    }
    
    public var fileURL: URL? {
        if let path = imagePath() {
            return URL(fileURLWithPath: path)
        }
        return nil
    }
    
    private func imagePath() -> String? {
        return sourecePath(imageName: rawValue)
    }
    
    private func sourecePath(imageName: String) -> String? {
        let assetBundle = Bundle.chatAssetBundle
        switch self {
        case .soundwave_w_s, .soundwave_b_s:
            return assetBundle.path(forResource: "chat_" + imageName, ofType: "gif", inDirectory: "Images")
        default:
            return assetBundle.path(forResource: "chat_" + imageName + "@2x", ofType: "png", inDirectory: "Images")
        }
    }
    
    private func stretch(_ image: UIImage) -> UIImage {
        
        let hor = image.size.width / 2
        let top = image.size.height * 0.7
        let bottom = image.size.height * 0.3
        
        let capInsets = UIEdgeInsets(top: top, left: hor, bottom: bottom, right: hor)
        return image.resizableImage(withCapInsets: capInsets, resizingMode: .stretch)
    }
}

