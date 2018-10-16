//
//  ProximityManager.swift
//  Alamofire
//
//  Created by 武飞跃 on 2017/12/13.
//  传感器

import Foundation
import AVFoundation

final class ProximityManager {
    
    init() {
        addListener()
    }
    
    deinit {
        removeListener()
    }
    
    func open() {
        //这个功能是开启红外感
        UIDevice.current.isProximityMonitoringEnabled = true
    }
    
    func close() {
        UIDevice.current.isProximityMonitoringEnabled = false
    }
    
    private func addListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(sensorStateChange), name: .UIDeviceProximityStateDidChange, object: nil)
    }
    
    private func removeListener() {
        NotificationCenter.default.removeObserver(self, name: .UIDeviceProximityStateDidChange, object: nil)
    }
    
    @objc
    private func sensorStateChange(_ notification: Notification) {
        if UIDevice.current.proximityState == true {
            //开启红外
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayAndRecord)
        }
        else{
            try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        }
    }
}
