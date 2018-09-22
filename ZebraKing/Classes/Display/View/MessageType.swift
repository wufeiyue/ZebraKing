//
//  MessageType.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/6.
//

import Foundation
import IMMessageExt
import CoreLocation

//MARK: - 消息状态

public enum MessageStatus {
    
    /// 消息发送中
    case sending
    
    /// 消息发送成功
    case success
    
    /// 消息发送失败
    case failure
    
    /// 消息被删除
    case deleted
    
    /// 导入到本地的消息
    case stored
    
    /// 被撤销的消息
    case revoked
}

public protocol MessageType {
    
    var sender: Sender { get }
    
    /// 唯一Id, 根据此id, 在字典中取缓存布局
    var messageId: String { get }
    
    var data: MessageData { get }
    
    /// 消息状态是否已读
    var isRead: Bool { get }
    
    /// 发送状态
    var status: MessageStatus { get }
    
    static func msg(with date: Date) -> Self
}

public final class MessageElem: NSObject {

    let msg: TIMMessage
    
    /// 是否需要显示消息所有者的名字
    public var isShowDisplayName: Bool = false
    
    private var displayName: String {
        //获取发送者资料（发送者为自己时可能为空）
        let profile: TIMUserProfile = msg.getSenderProfile()
        return profile.nickname
    }
    
    init(msg: TIMMessage) {
        self.msg = msg
    }
    
//    private func/
    
    private func convertMessageData() -> MessageData {
        if let message = msg.getElem(0) as? TIMTextElem {
            //纯文本
            return .text(message.text)
        }
        else if let message = msg.getElem(0) as? TIMImageElem {
            //图片
            //FIXME: 未测试图片显示
            if let imageList = message.imageList as? [UIImage], let firstImage = imageList.first {
                return .photo(firstImage)
            }
            else if let image = UIImage(contentsOfFile: message.path) {
                return .photo(image)
            }
            else {
                //FIXME: - 加载失败的图片
                let loadFailureImage = UIImage(named: "")!
                return .photo(loadFailureImage)
            }
        }
        else if let message = msg.getElem(0) as? TIMLocationElem {
            //位置
            let clLocation: CLLocation = CLLocation(latitude: message.latitude, longitude: message.longitude)
            return .location(clLocation)
        }
        else if let message = msg.getElem(0) as? TIMSoundElem {
            //音频
            return .audio(path: message.path, second: message.second)
        }
        else if let message = msg.getElem(0) as? TIMCustomElem {
            //自定义消息
            return .custom(message.data)
        }
        else {
            return .text("[不支持的消息类型]")
        }
    }
}

extension MessageElem: MessageType {
    
    public var status: MessageStatus {
        return .sending
    }
    
    
    public var isRead: Bool {
        return true
    }
    
    
    public var sender: Sender {
        return Sender(id: msg.sender(), displayName: displayName)
    }
    
    public var messageId: String {
        return msg.msgId()
    }
    
    public var data: MessageData {
        return convertMessageData()
    }
    
    public static func msg(with date: Date) -> MessageElem {
        let timeEle = TIMCustomElem()
        timeEle.data = NSKeyedArchiver.archivedData(withRootObject: date)
        let msgEle = TIMMessage()
        msgEle.add(timeEle)
        return MessageElem(msg: msgEle)
    }

}

