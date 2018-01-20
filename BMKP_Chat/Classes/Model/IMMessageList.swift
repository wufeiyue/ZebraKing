//
//  IMMessageList.swift
//  Alamofire
//
//  Created by 武飞跃 on 2017/12/19.
//

import Foundation
import IMMessageExt
import ImSDK

public struct IMMessageList {
    
    enum StackType {
        case append
        case remove
    }
    
    public private(set) var list = Array<IMMessage>()
    public private(set) var messageCount: Int = 0
    private var type: StackType = .append
    
    var indexRows: Array<IndexPath> {
        
        let iterator:(Int) -> (Int) = { value -> Int in
            return self.type == .remove ? value : -value - 1
        }
        
        var tempIndexPaths = [IndexPath]()
        for i in 0 ..< messageCount {
            tempIndexPaths.append(IndexPath(row: list.count + iterator(i), section: 0))
        }
        return tempIndexPaths
    }
    
    mutating func append(_ newElement: IMMessage) {
        let willSendList = addMsgToList(msg: newElement)
        willSendList.forEach {
            list.append($0)
        }
        messageCount = willSendList.count
        type = .append
    }
    
    mutating func removeLast() {
        (0..<messageCount).forEach { _ in
            list.removeLast()
        }
        type = .remove
    }
    
    mutating func replace(_ newElement: IMMessage) {
        removeLast()
        append(newElement)
    }
    
    public mutating func removeSubrange(num: Int) {
        list.removeSubrange((list.count - num)...list.count)
    }
    
    private func addMsgToList(msg followMessage: IMMessage) -> [IMMessage] {
        var array = Array<IMMessage>()
        if let timeTip = timeTipOnNewMessageIfNeeded(last: list.last, follow: followMessage) {
            array.append(timeTip)
        }
        array.append(followMessage)
        return array
    }
    
    private func timeTipOnNewMessageIfNeeded(last:IMMessage?, follow:IMMessage) -> IMMessage?{
        
        if let followDate = follow.msg.timestamp() {
            guard let lastDate = last?.msg.timestamp() else {
                return IMMessage.msgWithDate(timetip: followDate)
            }
            if followDate.timeIntervalSince(lastDate) > TimeInterval(5*60) {
                //大于5分钟
                return IMMessage.msgWithDate(timetip: followDate)
            }
        }
        return nil
    }
}

extension IMMessageList {
    var isEmpty: Bool {
        return list.isEmpty
    }
    
    var count: Int {
        return list.count
    }
    
    func index(of: IMMessage) -> Int? {
        return list.index(of: of)
    }
    
    mutating func inset(newsList: Array<IMMessage>) {
        list = newsList + list
    }
    
    mutating func addList(newsList: Array<IMMessage>) {
        list = list + newsList
    }
    
    subscript(index: Int) -> IMMessage {
        return list[index]
    }
}
