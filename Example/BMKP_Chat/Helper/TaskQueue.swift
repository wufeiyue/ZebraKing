//
//  TaskQueue.swift
//  BMChat_Example
//
//  Created by 武飞跃 on 2017/11/1.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation

enum TaskStatus {
    case normal
    case success
    case faliure
}

typealias  StatusCompletion = (Bool) -> Void

final class TaskQueueItem {
    var title: String
    var tips: String?
    var closure: () -> Bool
    var invaild: TaskStatus = .normal
    
    init(title: String, tips: String, closure:@escaping ()-> Bool) {
        self.tips = tips
        self.title = title
        self.closure = closure
    }
}

final class TaskQueue {
    
    
    let queue: Array<TaskQueueItem>
    var result: (() -> Void)?
    var isRetryLast: Bool = false    //是否可重复执行索引的最后一个
    private(set) var parallel = Array<TaskQueueItem>()   //并行队列
    private var nextQueueItem: TaskQueueItem?
    
    init(queue: Array<TaskQueueItem>) {
        self.queue = queue
    }
    
    func execute(at: Int, section: Int) {
        
        if section == 0 {
            serial(at: at)
        }
        else if let item = nextQueueItem{
            parallel(at: at, item: item)
        }
        
    }
    
    //执行串行队列
    private func serial(at: Int) {
        
        let proton = iterator()

        func next(i: Int) {
            
            if i > at {
                if isRetryLast {
                    _ = queue[at].closure()
                }
                return
            }
            
            if queue[i].invaild == .success {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                    next(i: proton())
                })
            }
            else {
                
                if queue[i].closure() {
                    queue[i].invaild = .success
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                        next(i: proton())
                    })
                }
                else{
                    queue[i].invaild = .faliure
                    queue.dropFirst(i).forEach {
                        $0.invaild = .faliure
                    }
                    
                }
                result?()
            }
        }
        
        next(i: 0)
    }
    
    //执行并行队列
    private func parallel(at: Int, item: TaskQueueItem) {
        if item.invaild == .success {
            _ = parallel[at].closure()
            return
        }
        
    }
    
    func isExecuted(at: Int) -> TaskStatus {
        return queue[at].invaild
    }
    
    func start() {
        execute(at: queue.count - 1, section: 0)
    }
    
    //添加一个并行队列, 需要再在指定item返回成功结果之后
    func addParallel(_ list: Array<TaskQueueItem>, nextStartExecuted item: TaskQueueItem) {
        list.forEach{ self.parallel.append($0) }
        nextQueueItem = item
    }
    
    private func iterator() -> () -> Int {
        var i = 0
        return {
            i += 1
            return i
        }
    }
    
}
