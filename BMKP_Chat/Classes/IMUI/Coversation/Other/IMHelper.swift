//
//  IMHelper.swift
//  test
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import Foundation
import UIKit

private class BundleClass: NSObject {}

extension Bundle {
    public static let chat: Bundle = .init(for: BundleClass.self)
    public static let chatResources: Bundle = Bundle.init(url: Bundle.chat.url(forResource: "BMKP_Chat", withExtension: "bundle")!)!
    
    
    public static var displayName: String {
        if let infoDictionary = Bundle.main.infoDictionary {
            CFShow(infoDictionary as CFTypeRef)
            if let appName = infoDictionary["CFBundleDisplayName"] {
                return appName as! String
            }
        }
        return "此App"
    }
}

//FIXME: - 先放在这,为了独立IM模块, 目前还没有找到更好的方案

/// listener name and action
public struct Listener<T>: Hashable {
    
    public typealias Action = (T) -> Void
    
    public let key: String
    public let action: Action
    
    public var hashValue: Int {
        return key.hashValue
    }
    
}

public func ==<T>(lhs: Listener<T>, rhs: Listener<T>) -> Bool {
    return lhs.key == rhs.key
}


/// T is the object you want listen
public class ListenAble<T> {
    
    public typealias GuardItem = (new: T, old: T)
    
    public typealias GuardAction = (GuardItem) -> Bool
    public typealias SetterAction = (T) -> Void
    public typealias OptionalEscapeingAction = (T, @escaping () -> Void) -> Void
    
    /// fire the action that you listened when you change this value
    public private(set) var value: T {
        didSet {
            setterAction(value)
            listenerSet.forEach {
                $0.action(value)
            }
        }
    }
    
    var updateGuard: GuardAction
    var setterAction: SetterAction
    var listenerSet = Set<Listener<T>>()
    
    /// init
    ///
    /// - Parameters:
    ///   - v: init value of T
    ///   - filter: a filter of updateValue
    ///   - action: init action of T, it will exist forever
    public init(v: T, `guard`: GuardAction? = nil, setter: @escaping SetterAction = { _ in }) {
        value = v
        setterAction = setter
        updateGuard = `guard` ?? { _ in return true }
    }
    
    /// 更新 value
    ///
    /// - Parameter v: value
    public func updateValue(_ v: T) {
        guard updateGuard((new: v, old: value)) else { return }
        value = v
    }
    
    /// bind listener
    ///
    /// - Parameters:
    ///   - key: unique key
    ///   - count: trigger count, default is nil and no limit
    ///   - action: action will execute when value changed
    @discardableResult
    public func bindListener(key: String = UUID().uuidString, count: Int? = nil, action: @escaping Listener<T>.Action) -> String {
        if let count = count, count > 0 {
            let counter = createCounter(start: count)
            listenerSet.insert(Listener<T>(key: key, action: { [weak self] t in
                action(t)
                if counter() == 0 {
                    self?.removeListener(key: key)
                }
            }))
        } else {
            listenerSet.insert(Listener<T>(key: key, action: action))
        }
        return key
    }
    
    /// bind listener and fire immediately
    ///
    /// - Parameters:
    ///   - key: unique key
    ///   - count: trigger count, default is nil and no limit, immediately fire not change count
    ///   - action: action will execute when value changed
    @discardableResult
    public func bindAndFireListener(key: String = UUID().uuidString, count: Int? = nil, action: @escaping Listener<T>.Action) -> String {
        defer {
            action(value)
        }
        return bindListener(key: key, count: count, action: action)
    }
    
    /// only fire once
    ///
    /// - Parameters:
    ///   - action: action will execute when value changed
    public func fireOnce(_ action: @escaping Listener<T>.Action) {
        _ = bindListener(count: 1, action: action)
    }
    
    /// 异步类型的一次性监听方法, 得到想要的数据之后，则执行 OptionalEscapeingAction 的第二个 clouse
    ///
    /// - Parameter action: OptionalEscapeingAction
    @discardableResult
    public func fireUntilCompleted(key: String = UUID().uuidString, _ completedAction: @escaping OptionalEscapeingAction) -> String {
        
        let finish = {
            self.removeListener(key: key)
        }
        
        bindListener(key: key, count: nil) {
            completedAction($0, finish)
        }
        
        completedAction(value, finish)
        
        return key
    }
    
    /// remove listener
    ///
    /// - Parameter key: bind key
    public func removeListener(key: String) {
        if let index = listenerSet.index(where: { $0.key == key }) {
            listenerSet.remove(at: index)
        }
    }
    
    /// remove all
    public func removeAll() {
        listenerSet.removeAll(keepingCapacity: false)
    }
    
    /// 创建一个计时器，没调用一次计数都会减一
    fileprivate func createCounter(start: Int) -> () -> Int {
        var startCount = start
        return {
            startCount -= 1
            return startCount
        }
    }
    
    
    
}
