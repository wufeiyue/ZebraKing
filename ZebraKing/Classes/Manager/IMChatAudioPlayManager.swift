//
//  IMChatAudioPlayManager.swift
//  ZebraKing
//
//  Created by gongjie on 2017/7/19.
//  Copyright © 2017年 ZebraKing. All rights reserved.
//

import UIKit
import AVFoundation
//import TSVoiceConverter

//MARK:  播放管理类
typealias AudioCompleteBlock = () -> ()

class IMChatAudioPlayManager: IMChatAudioManager {
    
    var soundPlayer: AVAudioPlayer?
    public var playCompletion: AudioCompleteBlock?
    private var proximity:ProximityManager?
    private var session = AVAudioSession.sharedInstance()
    
    override init() {
        super.init()
        proximity = ProximityManager()
    }
    
    deinit {
        proximity = nil
    }
    
    func stopPlay() {
        
        if soundPlayer?.isPlaying == true {
           soundPlayer?.stop()
        }
        soundPlayer?.delegate = nil
        soundPlayer = nil
        playCompletion = nil
    }
    
    
    func playWith(data: Data, finish: @escaping AudioCompleteBlock){
        stopPlay()
        playCompletion = finish
        becomeFirstResponder()
        soundPlayer = try? AVAudioPlayer(data: data)
        if soundPlayer != nil {
            proximity?.open()
            soundPlayer?.delegate = self
            soundPlayer?.volume = 1
            soundPlayer?.prepareToPlay()
            soundPlayer?.play()
        }else{
            self.playCompletion?()
        }
    }
    
    func playWith(url: URL, finish: @escaping AudioCompleteBlock){
        stopPlay()
        playCompletion = finish
        becomeFirstResponder()
        soundPlayer = try? AVAudioPlayer(contentsOf: url)
        if soundPlayer != nil {
            proximity?.open()
            soundPlayer?.delegate = self
            soundPlayer?.volume = 1
            soundPlayer?.prepareToPlay()
            soundPlayer?.play()
        }else{
            playCompletion?()
        }
    }
    
    
    private func becomeFirstResponder() {
        if #available(iOS 10.0, *) {
            try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: .duckOthers)
        } else {
            // Fallback on earlier versions
        }
        try? session.setActive(true)
    }
    
    private func resignFirstResponder() {
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
}

extension IMChatAudioPlayManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playCompletion?()
        playCompletion = nil
        
        //播放完成
        proximity?.close()
        
        defer {
            resignFirstResponder()
        }
        
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        playCompletion?()
        playCompletion = nil
        
        proximity?.close()
        
        defer {
            resignFirstResponder()
        }
    }
}
