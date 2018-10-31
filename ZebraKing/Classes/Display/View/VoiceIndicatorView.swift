//
//  VoiceIndicatorView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/3/6.
//

import UIKit

open class VoiceIndicatorView: UIView {
    
    //是否完成录音
    public private(set) var isFinishRecording: Bool = false
    
    private let containerView: UIView = {
        $0.layer.cornerRadius = 4
        $0.layer.masksToBounds = true
        $0.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        return $0
    }(UIView())
    
    private let noteLabel: UILabel = {
        $0.layer.cornerRadius = 2.0
        $0.layer.masksToBounds = true
        $0.textColor = .white
        $0.font = UIFont.systemFont(ofSize: 14)
        $0.textAlignment = .center
        return $0
    }(UILabel())
    
    //录音整体的 view，控制是否隐藏
    private let recordingView: RecordingBackgroundView = RecordingBackgroundView()
    
    //录音时间太短的提示
    private let tooShotPromptImageView: UIImageView = {
        $0.image = MessageStyle.messageTooShort.image
        return $0
    }(UIImageView())
    
    //取消提示
    private let cancelImageView: UIImageView = {
        $0.image = MessageStyle.recordCancel.image
        return $0
    }(UIImageView())
    
    public override init (frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public convenience init () {
        self.init(frame: .zero)
        setup()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    private func setup() {
        isHidden = true
        addSubview(containerView)
        [noteLabel, cancelImageView, tooShotPromptImageView, recordingView].forEach{ containerView.addSubview($0) }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let containerSize: CGSize = CGSize(width: 150, height: 150)
        let contentSize: CGSize = CGSize(width: 100, height:100)
        
        containerView.center = center
        containerView.bounds.size = containerSize
        recordingView.bounds.size = contentSize
        recordingView.center = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2 - 10)
        noteLabel.frame = CGRect(x: 8, y: containerSize.height - 20 - 6, width: containerSize.width - 16, height: 20)
        cancelImageView.bounds.size = contentSize
        cancelImageView.center = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2 - 10)
        
        tooShotPromptImageView.bounds.size = contentSize
        tooShotPromptImageView.center = CGPoint(x: containerSize.width / 2, y: containerSize.height / 2 - 10)
    }
    
}

//对外交互的 view 控制
extension VoiceIndicatorView {
    //正在录音
    open func recording() {
        isHidden = false
        cancelImageView.isHidden = true
        tooShotPromptImageView.isHidden = true
        recordingView.isHidden = false
        noteLabel.backgroundColor = UIColor.clear
        noteLabel.text = "手指上滑，取消发送"
        isFinishRecording = true
    }
    
    //滑动取消
    open func slideToCancelRecord() {
        guard isHidden == false else { return }
        cancelImageView.isHidden = false
        tooShotPromptImageView.isHidden = true
        recordingView.isHidden = true
        noteLabel.backgroundColor = UIColor(red: 156/255.0, green: 54/255.0, blue: 56/255.0, alpha: 1.0)
        noteLabel.text = "松开手指，取消发送"
        isFinishRecording = false
    }
    
    //录音时间太短的提示
    open func messageTooShort() {
        isHidden = false
        cancelImageView.isHidden = true
        tooShotPromptImageView.isHidden = false
        recordingView.isHidden = true
        noteLabel.backgroundColor = UIColor.clear
        noteLabel.text = "说话时间太短"
        //0.5秒后消失
        let delayTime = DispatchTime.now() + 0.5
        DispatchQueue.main.asyncAfter(deadline: delayTime) {
            self.endRecord()
        }
    }
    
    //录音结束
    open func endRecord() {
        isHidden = true
    }
    
    //更新麦克风的音量大小
    open func updateMetersValue(_ value: Int) {
        recordingView.updateMetersValue(value)
    }
}

public final class RecordingBackgroundView: UIView {
    
    private var addressesView: UIImageView!
    private var signalView: RecordingSinalImageView!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    public init() {
        super.init(frame: .zero)
        setupView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func setupView() {
        
        addressesView = UIImageView()
        addressesView.image = MessageStyle.recordingBkg.image
        addSubview(addressesView)

        signalView = RecordingSinalImageView()
        signalView.image = MessageStyle.recordingSignal.image
        addSubview(signalView)
        
    }
    
    public func updateMetersValue(_ index: Int) {
        let list:Array<CGFloat> = [75, 75, 67, 56, 50, 40, 28, 20]
        guard index >= 0 && index < list.count else { return }
        signalView.updateMetersValue(list[index])
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        addressesView.frame = CGRect(x: 0, y: 0, width: 62, height: bounds.height)
        signalView.frame = CGRect(x: 62, y: 0, width: bounds.width - 62, height: bounds.height)
    }
}

public final class RecordingSinalImageView: UIImageView {
    
    private let animationKey = "recording-position-key"
    private var fromValue: CGFloat?
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayer()
    }
    
    public init() {
        super.init(frame: .zero)
        setupLayer()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLayer() {
        let pointLayer = CALayer()
        pointLayer.anchorPoint = .zero
        pointLayer.position = .zero
        pointLayer.backgroundColor = UIColor.black.cgColor
        layer.mask = pointLayer
    }
    
    public func updateMetersValue(_ value: CGFloat, duration: CFTimeInterval = 0.3) {
        
        let anim = CABasicAnimation(keyPath: "position")
        
        if let unwrappedFromValue = fromValue {
            anim.fromValue = NSValue(cgPoint: CGPoint(x: 0, y: unwrappedFromValue))
        }
        else {
            anim.fromValue = NSValue(cgPoint: CGPoint(x: 0, y: bounds.height))
        }
        
        anim.toValue = NSValue(cgPoint: CGPoint(x: 0, y: value))
        anim.duration = duration
        anim.isRemovedOnCompletion = false
        anim.fillMode = kCAFillModeForwards
        layer.mask?.add(anim, forKey: animationKey)
        
        fromValue = value
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        layer.mask?.bounds = bounds
    }
}
