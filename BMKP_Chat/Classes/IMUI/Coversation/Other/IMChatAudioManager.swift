//
//  IMChatAudioManager.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import Foundation
import AVFoundation

class IMChatAudioManager: NSObject {
    let maxTimeForRecording: Int32 = 60 //录音最长时间限制，超过停止录音
    let recordTimeInterval: TimeInterval = 0.05 //更新录音测量的时间间隔
}

