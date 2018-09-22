//
//  MessageData.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/6.
//

import Foundation
import class CoreLocation.CLLocation

public enum MessageData {
    
    //文本
    case text(String)
    
    //富文本
    case attributedText(NSAttributedString)
    
    //图片
    case photo(UIImage)
    
    //视频
    case video(file: URL, thumbnail: UIImage)
    
    //位置
    case location(CLLocation)
    
    //表情
    case emoji(String)
    
    //音频
    case audio(path: String, second: Int32)
    
    //时间戳
    case timestamp(Date)
    
    //自定义消息类型
    case custom(Data)
}
