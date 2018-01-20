//
//  IMChatSoundRecorder.swift
//  Alamofire
//
//  Created by 武飞跃 on 2017/12/21.
//

import Foundation
import AVFoundation
import TSVoiceConverter

//MARK: 录音代理回调
protocol IMChatAudioRecordDelegate: class  {
    /**
     录音完成
     - parameter recordTime:        录音时长
     - parameter uploadAmrData:     上传的 amr Data
     */
    func audioRecordFinish(_ uploadAmrData: Data, recordTime: TimeInterval)
}


enum ChatAudioError: Error {
    case initFail     //初始化失败
    case noAuthorize  //没有授权
}

enum ChatRecorderState {
    case stop           //停止
    case recoring       //正在录音中...
    case relaseCancel   //取消录音
    case maxRecord      //最大录音秒数
    case tooShort       //录音秒数太短了
    case prepare        //准备开始
}

final class IMChatSoundRecorder {
    
    //保存进来之前设置的, 出去的时候再设置回来
    private var audioSesstionCategory: String?
    private var audioSesstionMode: String?
    private var audioSesstionCategoryOptions: AVAudioSessionCategoryOptions?
    
    public weak var delegate: IMChatAudioRecordDelegate?
    public private(set) var recordSavePath: URL?
    public private(set) var recordState = ListenAble<ChatRecorderState>(v: .stop)
    public private(set) var recordPeak = ListenAble<Int>(v: 1)
    public private(set) var isVaildRecorder: Bool = false
    private var session: AVAudioSession!
    private var recorder: AVAudioRecorder?
    private var recordDuration: Int = 0
    private var recorderTimer: Timer?
    private var recorderPeakerTimer: Timer?
    private var needCheckFlag: Int = 1
    
    //请求录音权限失败的处理
    public var requestRecordPermissionFailure: (() -> Void)?
    
    let maxTimeForRecording: Int = 60
    
    init() {
        activeAudioSession()
    }
    
    deinit {
        let session = AVAudioSession.sharedInstance()
        if let unwrappedCategory = audioSesstionCategory, let unwarappedOptions = audioSesstionCategoryOptions {
            try? session.setCategory(unwrappedCategory, with: unwarappedOptions)
        }
        if let unwrappedMode = audioSesstionMode {
            try? session.setMode(unwrappedMode)
        }
    }
    
    private func activeAudioSession() {
        session = AVAudioSession.sharedInstance()
        try? session.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .duckOthers)
        audioSesstionCategory = session.category
        audioSesstionMode = session.mode
        audioSesstionCategoryOptions = session.categoryOptions
        try? session.setActive(true)
    }
    
    public func setNeedCheckIsVaildRecord() {
        needCheckFlag += 1
    }

    public func checkIsVaildRecordIfNeeded() {
        guard needCheckFlag > 0 else { return }
        
        AVAudioSession.sharedInstance().requestRecordPermission({ [weak self] (available: Bool) in
            if !available {
                DispatchQueue.main.async { [weak self] in
                    self?.requestRecordPermissionFailure?()
                    self?.isVaildRecorder = false
                }
            }
            else {
                self?.isVaildRecorder = true
                self?.needCheckFlag -= 1
            }
        })
    }
    
    /// 取消录音
    public func cancelRecord() {
        recordState.updateValue(.relaseCancel)
        stopRecord()
    }
    
    //开始录音
    public func startRecording() {
        if isVaildRecorder == false {
            setNeedCheckIsVaildRecord()
            checkIsVaildRecordIfNeeded()
            return
        }
        
        if case .tooShort = recordState.value {
            return
        }
        
        recorder?.stop()
        
        let canRecord = readyRecord()
        if canRecord == false {
            //初始化录音机失败
            return
        }
        
        recorder?.record()
        
        recordPeak.updateValue(1)
        recordDuration = 0
        recordState.updateValue(.recoring)
        
        if self.recorderPeakerTimer == nil {
            let recorderPeakerTimer = Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(onRecordPeak), userInfo: nil, repeats: true)
            RunLoop.current.add(recorderPeakerTimer, forMode: .commonModes)
            self.recorderPeakerTimer = recorderPeakerTimer
        }
        
        if self.recorderTimer == nil {
            let recorderTimer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(onRecording), userInfo: nil, repeats: true)
            RunLoop.current.add(recorderTimer, forMode: .commonModes)
            self.recorderTimer = recorderTimer
        }
    }
    
    /// 准备录音
    private func readyRecord() -> Bool {
        do {
            //基础参数
            let recordSettings:[String : AnyObject] = [
                //线性采样位数  8、16、24、32
                AVLinearPCMBitDepthKey: NSNumber(value: 16 as Int32),
                //设置录音格式  AVFormatIDKey
                AVFormatIDKey: NSNumber(value: kAudioFormatMPEG4AAC as UInt32),
                //录音通道数  1 或 2
                AVNumberOfChannelsKey: NSNumber(value: 1 as Int32),
                //设置录音采样率(Hz) 如：AVSampleRateKey == 8000/44100/96000（影响音频的质量）
                AVSampleRateKey: NSNumber(value: 44100.0 as Float),
                //录音的质量
                AVEncoderAudioQualityKey: NSNumber(value: Int8(AVAudioQuality.high.rawValue))
            ]
            
            let sanboxPath = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).last!
            let uuid = UUID().uuidString
            let strURL = sanboxPath + "/" + uuid + ".mp4"
            let tempWavRecordPath = URL(fileURLWithPath: strURL)
            
            self.recordSavePath = tempWavRecordPath
            self.recorder = try AVAudioRecorder(url: tempWavRecordPath, settings: recordSettings)
            
            //开启音量检测
            self.recorder?.isMeteringEnabled = true
            
            if self.recorder?.prepareToRecord() == true {
                return true
            }
            
        } catch {
            return false
        }
        
        return false
    }
    
    @objc
    private func onRecording () {
        recordDuration += 1
        
        if recordDuration == maxTimeForRecording {
            
            recordState.updateValue(.maxRecord)
            
            invalidate()
            stopRecord()
        }
        else if recordDuration == 1 {
            recordState.updateValue(.prepare)
        }
    }
    
    @objc
    private func onRecordPeak() {
        guard let recorder = recorder else { return }
        
        recorder.updateMeters()
        
        var peakPower:Float = 0
        peakPower = recorder.peakPower(forChannel: 0)
        peakPower = pow(10, (0.05 * peakPower))
        
        var peak = Int((peakPower * 100)/20 + 1)
        if peak < 1 {
            peak = 1
        }
        else if peak > 5 {
            peak = 5
        }
        
        if peak != recordPeak.value {
            recordPeak.updateValue(peak)
        }
    }
    
    /// 停止所有的定时器
    private func invalidate() {
        recorderTimer?.invalidate()
        recorderTimer = nil
        
        recorderPeakerTimer?.invalidate()
        recorderPeakerTimer = nil
    }
    
    /// 停止录音
    public func stopRecord() {
        
        invalidate()
        
        guard let recorder = recorder else { return }
        
        defer {
            self.recordState.updateValue(.stop)
            
            recorder.stop()
            
            let isExist = FileManager.default.fileExists(atPath: recorder.url.path)
            if recorder.isRecording == false && isExist {
                recorder.deleteRecording()
            }
            
        }
        
        if case .relaseCancel = recordState.value {
            return
        }
        
        let currentTime = recorder.currentTime
        
        //这里要和onRecording方法里的, 秒数保持一致, 因为如果这里设置0.5 然后用户录制秒数处于 0.6~1 之间时,就会crash, 因为只有当大于1秒,才会添加message到数组, 但是在0.6秒取消的时候, 会从数组中移除一个message, 就该挂掉了
        if currentTime < 1 {
            //录音太短
            recordState.updateValue(.tooShort)
        }
        else {
            recorder.stop() //此方法执行以后 currentTime被置为0
            
            if let path = recordSavePath, let data = try? Data(contentsOf: path) {
                delegate?.audioRecordFinish(data, recordTime: currentTime + 0.5)
            }
        }
        
    }
    
}
