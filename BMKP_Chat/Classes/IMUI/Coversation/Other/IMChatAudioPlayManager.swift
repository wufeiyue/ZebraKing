//
//  IMChatAudioPlayManager.swift
//  BMKP
//
//  Created by gongjie on 2017/7/19.
//  Copyright © 2017年 bmkp. All rights reserved.
//

import UIKit
import AVFoundation
import TSVoiceConverter

//MARK:  播放管理类
typealias AudioCompleteBlock = () -> ()

class IMChatAudioPlayManager: IMChatAudioManager {
    
    var soundPlayer: AVAudioPlayer?
    public var playCompletion: AudioCompleteBlock?
    private var proximity:ProximityManager?
    
    override init() {
        super.init()
        proximity = ProximityManager()
    }
    
    func stopPlay() {
        
        if soundPlayer?.isPlaying == true {
           soundPlayer?.stop()
        }
        soundPlayer?.delegate = nil
        soundPlayer = nil
        playCompletion = nil
        proximity = nil
    }
    
    func playWith(data: Data, finish: @escaping AudioCompleteBlock){
        stopPlay()
        playCompletion = finish
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
}


extension IMChatAudioPlayManager: AVAudioPlayerDelegate {
    
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playCompletion?()
        playCompletion = nil
    }
    
    func audioPlayerDecodeErrorDidOccur(_ player: AVAudioPlayer, error: Error?) {
        playCompletion?()
        playCompletion = nil
    }
}
