//
//  ChatSoundRecorder.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/5/15.
//

import Foundation
import AVFoundation

//MARK: 录音代理回调
public protocol ChatAudioRecordDelegate: class  {
    
    
    /// 录音完成
    ///
    /// - Parameters:
    ///   - uploadAmrData: 上传的 amr Data
    ///   - recordTime: 录音时长
    func audioRecordFinish(_ uploadAmrData: Data, recordTime: TimeInterval)
    
    
    /// 录音状态已经改变了的回调
    ///
    /// - Parameter status: 录音状态
    func audioRecordStateDidChange(_ status: ChatRecorderState)
    
    
    /// 录音的声音大小改变后的回调
    ///
    /// - Parameter value: 当前值
    func audioRecordPeakDidChange(_ value: Int)
    
    
    /// 请求录音权限失败的处理
    func audioRecordRequestPermissionFailure()
    
}

extension ChatAudioRecordDelegate {
    public func audioRecordFinish(_ uploadAmrData: Data, recordTime: TimeInterval) {}
    public func audioRecordStateDidChange(_ status: ChatRecorderState) {}
    public func audioRecordPeakDidChange(_ value: Int) {}
    public func audioRecordRequestPermissionFailure() {}
}

public enum ChatRecorderState {
    case stop                       //停止
    case recoring                   //正在录音中...
    case relaseCancelWillPrepare    //在未开始准备好的时候取消录音
    case relaseCancelDidPrepare     //已经准备好的时候取消录音
    case maxRecord                  //最大录音秒数
    case tooShort                   //录音秒数太短了
    case prepare                    //准备开始
}


final public class ChatSoundRecorder {
    
    public private(set) var recordSavePath: URL?
    public private(set) var recordState: ChatRecorderState = .stop
    public private(set) var recordPeak: Int = 1
    public private(set) var isVaildRecorder: Bool = false
    private weak var delegate: ChatAudioRecordDelegate?
    private var recorder: AVAudioRecorder?
    private var recordDuration: Int = 0
    private var recorderTimer: Timer?
    private var recorderPeakerTimer: Timer?
    private var needCheckFlag: Int = 1
    private var session = AVAudioSession.sharedInstance()
    
    let maxTimeForRecording: Int = 60
    
    public init(delegate: ChatAudioRecordDelegate) {
        self.delegate = delegate
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillEnterForeground), name: .UIApplicationWillEnterForeground, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc
    private func applicationWillEnterForeground() {
        setNeedCheckIsVaildRecord()
    }
    
    public func setNeedCheckIsVaildRecord() {
        needCheckFlag += 1
    }
    
    public func checkIsVaildRecordIfNeeded() {
        guard needCheckFlag > 0 else { return }
        
        AVAudioSession.sharedInstance().requestRecordPermission({ [weak self] (available: Bool) in
            if !available {
                DispatchQueue.main.async { [weak self] in
                    self?.delegate?.audioRecordRequestPermissionFailure()
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
        
        let currentTime = recorder?.currentTime
        
        if let unwrappedCurrentTime = currentTime, unwrappedCurrentTime >= 1 {
            recordState = .relaseCancelDidPrepare
            delegate?.audioRecordStateDidChange(.relaseCancelDidPrepare)
        }
        else {
            recordState = .relaseCancelWillPrepare
            delegate?.audioRecordStateDidChange(.relaseCancelWillPrepare)
        }
        stopRecord()
    }
    
    //开始录音
    public func startRecording() {
        
        if isVaildRecorder == false {
            setNeedCheckIsVaildRecord()
            checkIsVaildRecordIfNeeded()
            return
        }
        
        if case .tooShort = recordState {
            return
        }
        
        becomeFirstResponder()
        recorder?.stop()
        
        let canRecord = readyRecord()
        if canRecord == false {
            //初始化录音机失败
            return
        }
        
        recorder?.record()
        
        recordPeak = 1
        recordDuration = 0
        recordState = .recoring
        delegate?.audioRecordPeakDidChange(1)
        delegate?.audioRecordStateDidChange(.recoring)
        
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
    
    /// 停止录音
    public func stopRecord() {
        
        invalidate()
        
        guard let recorder = recorder else { return }
        
        defer {
            recordState = .stop
            delegate?.audioRecordStateDidChange(.stop)
            
            recorder.stop()
            resignFirstResponder()
            
            let isExist = FileManager.default.fileExists(atPath: recorder.url.path)
            if recorder.isRecording == false && isExist {
                recorder.deleteRecording()
            }
            
        }
        
        if .relaseCancelDidPrepare == recordState || .relaseCancelWillPrepare == recordState {
            return
        }
        
        let currentTime = recorder.currentTime
        
        //这里要和onRecording方法里的, 秒数保持一致, 因为如果这里设置0.5 然后用户录制秒数处于 0.6~1 之间时,就会crash, 因为只有当大于1秒,才会添加message到数组, 但是在0.6秒取消的时候, 会从数组中移除一个message, 就该挂掉了
        if currentTime < 1 {
            //录音太短
            recordState = .tooShort
            delegate?.audioRecordStateDidChange(.tooShort)
        }
        else {
            recorder.stop() //此方法执行以后 currentTime被置为0
            
            if let path = recordSavePath, let data = try? Data(contentsOf: path) {
                delegate?.audioRecordFinish(data, recordTime: currentTime + 0.5)
            }
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
            
            recordState = .maxRecord
            delegate?.audioRecordStateDidChange(.maxRecord)
            
            invalidate()
            stopRecord()
        }
        else if recordDuration == 1 {
            recordState = .prepare
            delegate?.audioRecordStateDidChange(.prepare)
        }
    }
    
    @objc
    private func onRecordPeak() {
        guard let recorder = recorder else { return }
        
        recorder.updateMeters()
        
        var peakPower: Float = 0
        peakPower = recorder.peakPower(forChannel: 0)
        peakPower = pow(10, (0.05 * peakPower))
        
        var peak = Int((peakPower * 100)/20 + 1)
        if peak < 1 {
            peak = 1
        }
        else if peak > 5 {
            peak = 5
        }
        
        if peak != recordPeak {
            recordPeak = peak
            delegate?.audioRecordPeakDidChange(peak)
        }
    }
    
    /// 停止所有的定时器
    private func invalidate() {
        recorderTimer?.invalidate()
        recorderTimer = nil
        
        recorderPeakerTimer?.invalidate()
        recorderPeakerTimer = nil
    }
    
    private func becomeFirstResponder() {
        try? session.setCategory(AVAudioSessionCategoryRecord, with: .duckOthers)
        try? session.setActive(true)
    }
    
    private func resignFirstResponder() {
        try? session.setActive(false)
    }
    
}
