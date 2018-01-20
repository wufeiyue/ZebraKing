//
//  IMMessage.swift
//  BMKP
//
//  Created by gongjie on 2017/7/16.
//  Copyright © 2017年 bmkp. All rights reserved.
//

import Foundation
import YYText
import ImSDK
import IMMessageExt

// 消息对象
public final class IMMessage: NSObject {
    public var msg: TIMMessage = TIMMessage()
    public var type: IMMessageType?
    private(set) var status:IMMessageStatus = .create
    public var richTextLayout: YYTextLayout?
    public var richTextLinePositionModifier: IMTextLinePosition?
    public var richTextAttributedString: NSMutableAttributedString?
    public var cellHeight: CGFloat = 0
    
    lazy var msgTime: String? = {
        let dateTim: Date = msg.timestamp()
        return dateTim.chatTimeToString
    }()
    
    //便利构造器
    convenience init(msg: TIMMessage, type: IMMessageType?) {
        self.init()
        self.msg = msg
        self.type = type
        self.status = IMMessageStatus.convert(from: msg.status())
    }
    
    convenience init(draft: TIMMessageDraft, type: IMMessageType) {
        self.init()
        self.msg = draft.transformToMessage()
        self.type = type
    }
    
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
    
    //时间对象构造对象
    public class func msgWithDate(timetip: Date) -> IMMessage {
        let timeEle = TIMCustomElem()
        timeEle.data = NSKeyedArchiver.archivedData(withRootObject: timetip)
        let msgEle = TIMMessage()
        msgEle.add(timeEle)
        return IMMessage(msg: msgEle , type: .timeTip)
    }
    
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
    
    //草稿构造对象
    public class func msgWithDraft(draft: TIMMessageDraft) -> IMMessage{
        return IMMessage(draft: draft, type: .text)
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
    
    //是否已读
    public var isRead: Bool {
        return msg.isPeerReaded()
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
        
        let path = "\(cachePath)/\(loginId)/\(elem.uuid)"
        
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

extension IMMessage {
    
    //更新消息状态
    public func updateState(with status: IMMessageStatus) {
        self.status = status
    }
    
    /// 仅支持显示在页面的messageTyoe
    public var isVailedType: Bool {
        return type != .timeTip && type != .saftyTip
    }
}

