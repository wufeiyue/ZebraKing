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
        NotificationCenter.default.addObserver(self, selector: #selector(sensorStateChange), name: UIDevice.proximityStateDidChangeNotification, object: nil)
    }
    
    private func removeListener() {
        NotificationCenter.default.removeObserver(self, name: UIDevice.proximityStateDidChangeNotification, object: nil)
    }
    
    @objc
    private func sensorStateChange(_ notification: Notification) {
        if UIDevice.current.proximityState == true {
            //开启红外
            if #available(iOS 10.0, *) {
                try? AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            } else {
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playAndRecord)
            }
        }
        else{
            if #available(iOS 10.0, *) {
                try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .defaultToSpeaker)
            } else {
                AVAudioSession.sharedInstance().perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
            }
        }
    }
}
