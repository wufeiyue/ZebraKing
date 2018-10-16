//
//  IMResult.swift
//  BMChat_Example
//
//  Created by 武飞跃 on 2017/10/28.
//  Copyright © 2017年 CocoaPods. All rights reserved.
//

import Foundation

public typealias SendResultCompletion = (_ result: IMResult<Bool>) -> Void
public typealias LoadResultCompletion = (_ result: IMResult<Array<MessageElem>>) -> Void
public typealias MessageListCompletion = (_ message: Array<MessageElem>) -> Void
public typealias CountCompletion = (Int) -> Void
public typealias EmptyCompletion = () -> Void


