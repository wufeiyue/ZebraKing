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
    
}

public protocol TimestampType: class {
    init(dateMessage: Date)
}

public final class MessageElem {

    private var dateMessage: Date?
    
    public private(set) var message: TIMMessage!
    public var messageSender: Sender?
    
    /// 时间戳构造方法
    ///
    /// - Parameter dateMessage: 日期
    init(dateMessage: Date) {
        self.dateMessage = dateMessage
    }
    
    
    init(message: TIMMessage) {
        self.message = message
    }
    
    
    /// 文本构造方法
    ///
    /// - Parameter text: 文本内容
    init(text: String, sender: Sender?) {
        
        let textEle = TIMTextElem()
        textEle.text = text
        
        let msgEle = TIMMessage()
        msgEle.add(textEle)
        
        self.message = msgEle
        self.messageSender = sender
    }
    
    
    /// 语音构造方法
    ///
    /// - Parameters:
    ///   - data: 音频二进制数据
    ///   - dur: 音频时长
    init(data: Data, dur: Int32, sender: Sender?) {
        
        let soundEle = TIMSoundElem()
        
        if let path = saveDataToLocal(with: data) {
            soundEle.path = path
            soundEle.second = dur
        }
        
        let msgEle = TIMMessage()
        msgEle.add(soundEle)
        
        self.message = msgEle
        self.messageSender = sender
    }
    
}

//MARK: - 语音消息
extension MessageElem {
    
    /// 保存数据到本地
    ///
    /// - Parameter with: 语音data
    private func saveDataToLocal(with data: Data) -> String? {
        
        guard let loginId = TIMManager.sharedInstance().getLoginUser() else { return nil }
        
        let cachePath = PathUtility.getCachePath()
        
        let soundSaveDir = "\(cachePath)/\(loginId)/Audio"
        
        if PathUtility.isExistFile(path: soundSaveDir) == false {
            do {
                try FileManager.default.createDirectory(atPath: soundSaveDir, withIntermediateDirectories: true, attributes: nil)
            }catch {
                return nil
            }
        }
        
        let durationString = String(format:"%llu", Date().timeIntervalSince1970)
        let soundSavePath = "\(soundSaveDir)/\(durationString)"
        
        if PathUtility.isExistFile(path: soundSavePath) == false {
            let state = FileManager.default.createFile(atPath: soundSavePath, contents: nil, attributes: nil)
            if !state {
                return nil
            }
        }
        
        let isWrite = NSData(data: data).write(toFile: soundSavePath, atomically: true)
        if isWrite == false {
            return nil
        }
        return soundSavePath
    }
    
    public func getSoundPath(succ: @escaping (URL?) -> Void, fail: @escaping TIMFail) {
        guard let loginId = TIMManager.sharedInstance().getLoginUser(),
            let elem = message.getElem(0) as? TIMSoundElem else { return }
        
        let cachePath = PathUtility.getCachePath()
        let audioDir = "\(cachePath)/\(loginId)"
        var isDir: ObjCBool = false
        let isDirExist = FileManager.default.fileExists(atPath: audioDir, isDirectory: &isDir)
        
        if !(isDir.boolValue && isDirExist) {
            let isCreateDir = PathUtility.createDirectory(atCache: loginId)
            if isCreateDir == false {
                return
            }
        }
        
        let uuid = elem.uuid ?? ""
        let path = "\(cachePath)/\(loginId)/" + uuid
        
        if PathUtility.isExistFile(path: path) {
            succ(URL(fileURLWithPath: path))
        }
        else {
            elem.getSound(path, succ: {
                succ(URL(fileURLWithPath: path))
            }, fail: fail)
        }
        
    }
    
}

extension MessageElem: MessageType {
    
    //获取最后一条msg的元素的description
    public var messageTip: String? {
        
        let type: TIMConversationType = message.getConversation().getType()
        
        guard let ele: TIMElem = message.getElem(0) else { return nil }
        
        switch type {
        case .C2C:
            
            switch ele {
            case is TIMTextElem:
                return (ele as? TIMTextElem)?.text
            case is TIMSoundElem:
                return "[语音消息]"
            case is TIMImageElem:
                return "[图片]"
            case is TIMFileElem:
                return "[文件]"
            case is TIMLocationElem:
                return "[地理位置]"
            default:
                return "未知消息类型"
            }
            
        case .GROUP:
            return "收到一条群消息"
        case .SYSTEM:
            return "收到一条系统消息"
        }
    }
    
    var timestamp: Date {
        return message.timestamp()
    }
    
    /*
     可过滤的消息类型:
     TIMTextElem
     TIMImageElem
     TIMFileElem
     TIMFaceElem
     TIMLocationElem
     TIMSoundElem
     TIMVideoElem
     TIMCustomElem
     TIMProfileSystemElem
     TIMSNSSystemElem
     */
    
    //是否是无效的消息类型
    var isVailedType: Bool {
        return dateMessage == nil
    }
    
    //FIXME: - 页面消失时, 也会调用此方法
    public var sender: Sender {
        if dateMessage != nil {
            return Sender(id: "timestamp")
        }
        else if let unwrappedSender = messageSender {
            return unwrappedSender
        }
        else if let profile = message.getSenderProfile() {
            
            var sender = Sender(id: profile.identifier)
            sender.facePath = profile.faceURL
            sender.displayName = profile.nickname
            
            return sender
        }
        else {
            return Sender(id: message.sender())
        }
    }
    
    public var messageId: String {
        if dateMessage != nil {
            return "timestamp"
        }
        else {
            return message.msgId()
        }
    }
    
    public var data: MessageData {
        if let unwrappedTimestamp = dateMessage {
            return .timestamp(unwrappedTimestamp)
        }
        else {
            return convertMessageData()
        }
    }
    
    public var isRead: Bool {
        if dateMessage != nil {
            return true
        }
        else {
            if message.sender().isEmpty {
                return false
            }
            return message.isPeerReaded()
        }
    }
    
    public var status: MessageStatus {
        if dateMessage != nil {
            return .success
        }
        else {
            switch message.status() {
            case .MSG_STATUS_HAS_DELETED:
                return .deleted
            case .MSG_STATUS_LOCAL_REVOKED:
                return .revoked
            case .MSG_STATUS_LOCAL_STORED:
                return .stored
            case .MSG_STATUS_SEND_SUCC:
                return .success
            case .MSG_STATUS_SENDING:
                return .sending
            case .MSG_STATUS_SEND_FAIL:
                return .failure
            }
        }
    }
    
    private func convertMessageData() -> MessageData {
        if let message = message.getElem(0) as? TIMTextElem {
            
            //如果是纯文本的fontSize需要再MessagesCollectionViewFlowLayout类初始化时设置
            let attributedText = NSAttributedString(string: message.text, attributes: [
                .font: UIFont.systemFont(ofSize: 15),
                .foregroundColor: UIColor.blue
                ])
            
            //纯文本
            return .attributedText(attributedText)
        }
        else if let message = message.getElem(0) as? TIMImageElem {
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
        else if let message = message.getElem(0) as? TIMLocationElem {
            //位置
            let clLocation: CLLocation = CLLocation(latitude: message.latitude, longitude: message.longitude)
            return .location(clLocation)
        }
        else if let message = message.getElem(0) as? TIMSoundElem {
            //音频
            return .audio(path: message.path, second: message.second)
        }
        else if let message = message.getElem(0) as? TIMCustomElem {
            //自定义消息
            return .custom(message.data)
        }
        else {
            return .text("[不支持的消息类型]")
        }
    }
}

extension MessageElem: Hashable {
    
    public var hashValue: Int {
        return message.hashValue
    }
    
    public static func == (lhs: MessageElem, rhs: MessageElem) -> Bool {
        return lhs.message == rhs.message
    }
}
