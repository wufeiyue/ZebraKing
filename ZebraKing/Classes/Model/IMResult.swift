//
//  IMResult.swift
//  BMChat_Example
//
//  Created by 武飞跃 on 2017/10/28.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation

public typealias SendResultCompletion = (_ result: SendResult) -> Void
public typealias LoadResultCompletion = (_ result: LoadResult) -> Void
public typealias MessageListCompletion = (_ message: Array<IMMessage>) -> Void
public typealias MessageCompletion = (_ message: IMMessage) -> Void
public typealias CountCompletion = (Int) -> Void
public typealias EmptyCompletion = () -> Void

public enum LoadResult {
    case success(Array<IMMessage>)
    case failure(NSError)
}

public enum SendResult {
    case success
    case failure(NSError)
}
