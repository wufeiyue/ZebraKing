//
//  SafelyQueue.swift
//  BMChat_Example
//
//  Created by 武飞跃 on 2017/10/27.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation

//进入主线程执行block
func dispatch_async_safely_to_main_queue(_ block: @escaping ()->()) {
    dispatch_async_safely_to_queue(DispatchQueue.main, block)
}

//进入指定线程异步执行block
func dispatch_async_safely_to_queue(_ queue: DispatchQueue, _ block: @escaping ()->()) {
    if queue === DispatchQueue.main && Thread.isMainThread {
        block()
    } else {
        queue.async {
            block()
        }
    }
}
