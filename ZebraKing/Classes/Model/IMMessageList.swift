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
    
    public private(set) var list = Array<MessageElem>()
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
    
    var indexSet: IndexSet {
        
        let iterator:(Int) -> (Int) = { value -> Int in
            return self.type == .remove ? value : -value - 1
        }
        
        var tempSections = [Int]()
        for i in 0 ..< messageCount {
            tempSections.append(list.count + iterator(i))
        }
        
        return IndexSet(tempSections)
    }
    
    mutating func append(_ newElement: MessageElem) {
        
        var willSendListCount: Int = 1
        
        if let timeTip = timeTipOnNewMessageIfNeeded(last: list.last, follow: newElement) {
            list.append(timeTip)
            willSendListCount += 1
        }
        
        list.append(newElement)
        
        messageCount = willSendListCount
        type = .append
    }
    
    mutating func removeLast() {
        (0..<messageCount).forEach { _ in
            list.removeLast()
        }
        type = .remove
    }
    
    mutating func replaceLast(_ newElement: MessageElem) {
        guard list.isEmpty == false else { return }
        let range: Range<Int> = list.count - 1 ..< list.count
        list.replaceSubrange(range, with: [newElement])
    }
    
    public mutating func removeSubrange(num: Int) {
        list.removeSubrange((list.count - num)...list.count)
    }
    
    private func timeTipOnNewMessageIfNeeded(last: MessageElem?, follow: MessageElem) -> MessageElem?{
        
        let followDate = follow.timestamp
        
        guard let lastDate = last?.timestamp else {
            return MessageElem(dateMessage: followDate)
        }
        
        if followDate.timeIntervalSince(lastDate) > TimeInterval(5*60) {
            //大于5分钟
            return MessageElem(dateMessage: followDate)
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
    
    func index(of: MessageElem) -> Int? {
        return list.index(of: of)
    }
    
    mutating func inset(newsList: Array<MessageElem>) {
        list = newsList + list
    }
    
    mutating func addList(newsList: Array<MessageElem>) {
        list = list + newsList
    }
    
    subscript(index: Int) -> MessageElem {
        return list[index]
    }
}
