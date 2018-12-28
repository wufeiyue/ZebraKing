//
//  ChatAudioPlayManager.swift
//  ZebraKing
//
//  Created by 武飞跃 on 2017/7/19.
//  Copyright © 2017年 ZebraKing. All rights reserved.
//

import UIKit
import AVFoundation

//MARK: 播放管理类
public typealias AudioCompleteBlock = () -> ()

open class ChatAudioPlayManager: NSObject {
    
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
//        try? session.setCategory(convertFromAVAudioSessionCategory(AVAudioSession.Category.playback), with: .duckOthers)
        
        if #available(iOS 10.0, *) {
            try? session.setCategory(.playback, mode: .default, options: .duckOthers)
        } else {
            session.perform(NSSelectorFromString("setCategory:error:"), with: AVAudioSession.Category.playback)
        }
        
        try? session.setActive(true)
    }
    
    private func resignFirstResponder() {
        try? session.setActive(false, options: .notifyOthersOnDeactivation)
    }
}

extension ChatAudioPlayManager: AVAudioPlayerDelegate {
    
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playCompletion?()
        playCompletion = nil
        
        //播放完成
        proximity?.close()
        
        defer {
            resignFirstResponder()
        }
        
    }
    
    public func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        playCompletion?()
        playCompletion = nil
        
        proximity?.close()
        
        defer {
            resignFirstResponder()
        }
    }
}
