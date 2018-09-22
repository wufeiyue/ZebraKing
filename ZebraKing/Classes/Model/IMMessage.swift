//
//  IMMessage.swift
//  ZebraKing
//
//  Created by gongjie on 2017/7/16.
//  Copyright © 2017年 ZebraKing. All rights reserved.
//

import Foundation
//import YYText
import ImSDK
import IMMessageExt
import CoreLocation

// 消息对象
public final class IMMessage: NSObject {
    
    public var msg: TIMMessage = TIMMessage()
    public var type: IMMessageType
    
    public var receiver: Sender?
    
    private var timeTip: Date?
    
    //以下代码要注释
//    public var richTextLayout: YYTextLayout?
//    public var richTextLinePositionModifier: IMTextLinePosition?
//    public var richTextAttributedString: NSMutableAttributedString?
//    public var cellHeight: CGFloat = 0
    //以上代码要注释
    
    lazy var msgTime: String? = {
        let dateTim: Date = msg.timestamp()
        return dateTim.chatTimeToString
    }()
    
    //便利构造器
    init(msg: TIMMessage, type: IMMessageType) {
        self.type = type
        super.init()
        self.msg = msg
    }
    
    init(timetip: Date) {
        self.type = .timeTip
        super.init()
        timeTip = timetip
    }
}

extension IMMessage {
    
    //类工厂方法
    public class func msgWith(msg: TIMMessage) -> IMMessage? {
        let type = IMMessageType.convert(from: msg)
        return IMMessage(msg: msg, type: type)
    }
    
    //文本构建对象
    public class func msgWithText(text: String) -> IMMessage {
        let textEle = TIMTextElem()
        textEle.text = text
        let msgEle = TIMMessage()
        msgEle.add(textEle)
        return IMMessage(msg: msgEle , type: .text)
    }
    
    //FIXME: - 时间对象构造对象
//    public class func msgWithDate(timetip: Date) -> IMMessage {
//        let timeEle = TIMCustomElem()
//        timeEle.data = NSKeyedArchiver.archivedData(withRootObject: timetip)
//        let msgEle = TIMMessage()
//        msgEle.add(timeEle)
//        return IMMessage(msg: msgEle , type: .timeTip)
//    }
    
    //语音对象构造对象
    public class func msgWithSound(data: Data?, dur: Int32) -> IMMessage? {
        guard let unwrappedData = data else {
            return nil
        }
        
        let soundEle = TIMSoundElem()
        
        if let path = saveDataToLocal(with: unwrappedData) {
            soundEle.path = path
            soundEle.second = dur
        }
        
        let msgEle = TIMMessage()
        msgEle.add(soundEle)
        
        return IMMessage(msg: msgEle, type: .sound)
    }
    
    //空语音构造对象
    public class func msgWithEmptySound() -> IMMessage {
        let soundEle = TIMSoundElem()
        let msgEle = TIMMessage()
        msgEle.add(soundEle)
        return IMMessage(msg: msgEle, type: .sound)
    }
    
}

extension IMMessage {
    
    /// 仅支持显示在页面的messageTyoe
    public var isVailedType: Bool {
        return type != .timeTip && type != .saftyTip
    }
    
    
    public func removeMsg() {
        //删除消息TIMMessage--
        if type == .saftyTip || type == .timeTip {
            //不在IMSDK数据库里面，不能调remove接口
            return
        }
        msg.remove()
    }
    
    //是否是自己的消息
    public var isMineMsg: Bool {
        return msg.isSelf()
    }
    
    public var timestamp:TimeInterval {
        return msg.timestamp().timeIntervalSince1970
    }
    
    //获取最后一条msg的元素的description
    public var messageTip: String? {
        let type: TIMConversationType = msg.getConversation().getType()
        guard let ele: TIMElem = msg.getElem(0) else {
            return nil
        }
        if type == TIMConversationType.C2C {
            if ele is TIMTextElem {
                return (ele as? TIMTextElem)?.text
            }else if ele is TIMSoundElem {
                return "[语音消息]"
            }else{
                return "未知消息类型"
            }
        }
        return nil
    }
    
    /// 通过消息获取发送该消息的IMUserModel对象
    /// - Returns: IMUserModel对象
    public var getSender: IMUserModel? {
        if msg.getConversation().getType() == .C2C{
            return IMUserModel(userId: msg.sender())
        }
        return nil
    }
    
    public func getSoundPath (succ: @escaping (URL?) -> Void, fail: @escaping TIMFail) {
        guard let loginId = TIMManager.sharedInstance().getLoginUser(),
            let elem = msg.getElem(0) as? TIMSoundElem else { return }
        
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
            let url = URL(fileURLWithPath: path)
            succ(url)
        }
        else {
            elem.getSound(path, succ: {
                let url = URL(fileURLWithPath: path)
                succ(url)
            }, fail: fail)
        }
        
    }
    
    /// 保存数据到本地
    ///
    /// - Parameter with: 语音data
    private static func saveDataToLocal(with data: Data) -> String?{
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
    
}

extension IMMessage: MessageType {
    
    public var status: MessageStatus {
        switch msg.status() {
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
    
    
    //是否已读
    public var isRead: Bool {
        if msg.sender().isEmpty {
            return false
        }
        return msg.isPeerReaded()
    }
    
    public var data: MessageData {
        return convertMessageData()
    }
    
    public var sender: Sender {
        //消息没有发成功之前, 不知道是谁发的msg.sender()
        if let unwrappedReceiver = receiver {
            return unwrappedReceiver
        }
        
        return Sender(id: msg.sender())
    }
    
    //消息唯一的id
    public var messageId: String {
        return msg.msgId()
    }

    public static func msg(with date: Date) -> IMMessage {
        return IMMessage(timetip: date)
    }
    
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
        else if let timeTip = timeTip, type == .timeTip {
            return .timestamp(timeTip)
        }
        else {
            return .text("[不支持的消息类型]")
        }
    }
}
