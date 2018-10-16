//
//  MessagesList.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/8.
//

import Foundation

public struct MessagesList<T> where T: MessageType & TimestampType, T: Hashable {
    
    enum StackType {
        case append
        case remove
    }
    
    public private(set) var list = Array<T>()
    public private(set) var messageCount: Int = 0
    private var type: StackType = .append
    
    public var indexSet: IndexSet {
        
        let iterator:(Int) -> (Int) = { value -> Int in
            return self.type == .remove ? value : -value - 1
        }
        
        var tempSections = [Int]()
        for i in 0 ..< messageCount {
            tempSections.append(list.count + iterator(i))
        }
        
        return IndexSet(tempSections)
    }
    
    public init() {}
    
    public mutating func append(_ newElement: T) {
        let willSendList = addMsgToList(msg: newElement)
        willSendList.forEach {
            list.append($0)
        }
        messageCount = willSendList.count
        type = .append
    }
    
    public mutating func removeLast() {
        (0..<messageCount).forEach { _ in
            list.removeLast()
        }
        type = .remove
    }
    
    public mutating func replace(_ newElement: T) {
        removeLast()
        append(newElement)
    }
    
    public mutating func removeSubrange(num: Int) {
        list.removeSubrange((list.count - num)...list.count)
    }
    
    private func addMsgToList(msg followMessage: T) -> [T] {
        
        var array = Array<T>()
        
        if let timeTip = timeTipOnNewMessageIfNeeded(last: list.last, follow: followMessage) {
            array.append(timeTip)
        }
        
        array.append(followMessage)
        
        return array
        
    }
    
    private func timeTipOnNewMessageIfNeeded(last: T?, follow: T) -> T?{
        
        guard case .timestamp(let followDate) = follow.data else {
            return nil
        }
        
        guard case .timestamp(let lastDate)? = last?.data else {
            return T(dateMessage: followDate)
        }
        
        if followDate.timeIntervalSince(lastDate) > TimeInterval(5*60) {
            //大于5分钟
            return T(dateMessage: followDate)
        }
        
        return nil
    }
}

extension MessagesList {
    public var isEmpty: Bool {
        return list.isEmpty
    }
    
    public var count: Int {
        return list.count
    }
    
    public func index(of: T) -> Int? {
        return list.index(of: of)
    }
    
    public mutating func inset(newsList: Array<T>) {
        list = newsList + list
    }
    
    public mutating func addList(newsList: Array<T>) {
        list = list + newsList
    }
    
    public subscript(index: Int) -> T {
        return list[index]
    }
}

