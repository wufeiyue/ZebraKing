//
//  IMChatActionBarContainerView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2017/11/19.
//

import UIKit

//(此类被弃用)

public protocol IMChatActionBarContainerViewDelegate: class {
    func chatActionBarContainerView(_ view: UIView, btnStatus status: IMChatActionBarControlState)
}

public typealias IMChatActionBarContainerViewModel = (image: UIImage?, contentView: UIView)

public final class IMChatActionBarContainerView: UIView {

    //状态判断,单独抽离出来,以便于后期,根据不同的事件,通过switchBtnStatus状态值, 来展示逻辑
    public var switchBtnStatus: IMChatActionBarControlState = .selected
    public weak var delegate: IMChatActionBarContainerViewDelegate?
    //是否启用按钮切换事件, 默认是true
    public var isEnabledBtn:Bool = true {
        didSet {
            switchBtn.isEnabled = isEnabledBtn
            
            if isEnabledBtn {
                touchView.removeFromSuperview()
            }
            else {
                if subviews.filter({ $0 == touchView }).isEmpty {
                    addSubview(touchView)
                }
            }
            
        }
    }
    
    //为了便于给按钮置灰状态添加一个点击事件,给了一个可以响应事件的视图
    private lazy var touchView:UIView = { [unowned self] in
        let view = UIView()
        view.backgroundColor = UIColor.clear
        let tap = UITapGestureRecognizer(target: self, action: #selector(switchBtnDidTapped))
        view.addGestureRecognizer(tap)
        return view
    }()
    
    private var switchBtn: UIButton!
    private var normalContentView: UIView!
    private var selectedContentView: UIView!
    let swithMarginLeft: CGFloat = 10
    let swithWidthAndHeight: CGFloat = 33
    
    public init(frame: CGRect, normal: IMChatActionBarContainerViewModel, selected: IMChatActionBarContainerViewModel) {
        super.init(frame: frame)
        
        switchBtn = UIButton()
        switchBtn.addTarget(self, action: #selector(switchBtnDidTapped), for: .touchUpInside)
        switchBtn.setImage(normal.image, for: .normal)
        switchBtn.setImage(selected.image, for: .selected)
        addSubview(switchBtn)
        
        normalContentView = normal.contentView
        addSubview(normalContentView)
        
        selectedContentView = selected.contentView
        selectedContentView.isHidden = true
        addSubview(selectedContentView)
    }
    
    public func updateTouchAction(image: UIImage, contentView: UIView, status: IMChatActionBarControlState) {
        
        if status == .normal {
            normalContentView.removeFromSuperview()
            normalContentView = contentView
            switchBtn.setImage(image, for: .normal)
        }
        else if status == .selected {
            selectedContentView.removeFromSuperview()
            selectedContentView = contentView
            switchBtn.setImage(image, for: .selected)
        }
        else {
            switchBtn.setImage(image, for: .disabled)
        }
    }
    
    @objc
    public func switchBtnDidTapped() {
        if isEnabledBtn == false {
            delegate?.chatActionBarContainerView(self, btnStatus: .disabled)
            return
        }
        else {
            delegate?.chatActionBarContainerView(self, btnStatus: switchBtnStatus)
        }
        
        if switchBtnStatus == .normal {
            switchBtnStatus = .selected
            startAnimation(status: .normal)
            switchBtn.isSelected = false
        }
        else if switchBtnStatus == .selected{
            switchBtnStatus = .normal
            startAnimation(status: .selected)
            switchBtn.isSelected = true
        }
        
    }
    
    private func startAnimation(status: IMChatActionBarControlState) {
        if status == .selected{
            
            UIView.animate(withDuration: 0.3, animations: {
                self.normalContentView.alpha = 0
            }) { (isFinished) in
                self.normalContentView.isHidden = true
            }
            
            selectedContentView.alpha = 0
            selectedContentView.isHidden = false
            UIView.animate(withDuration: 0.3, animations: {
                self.selectedContentView.alpha = 1
            })
        }
        else if status == .normal {
            
            normalContentView.alpha = 1
            normalContentView.isHidden = false
            selectedContentView.isHidden = true
            selectedContentView.alpha = 0
        }
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        switchBtn.frame = CGRect(x: swithMarginLeft, y: 0, width: swithWidthAndHeight, height: swithWidthAndHeight)
        switchBtn.center.y = bounds.midY
        touchView.frame = CGRect(x: swithMarginLeft, y: 0, width: swithWidthAndHeight, height: swithWidthAndHeight)
        touchView.center.y = bounds.midY
        normalContentView.bounds = CGRect(x: 0, y: 0, width: frame.size.width - switchBtn.frame.maxX - swithMarginLeft, height: frame.size.height)
        normalContentView.center.x = bounds.midX + (switchBtn.frame.maxX + swithMarginLeft)/2
        normalContentView.center.y = bounds.midY
        selectedContentView.bounds = CGRect(x: 0, y: 0, width: frame.size.width - switchBtn.frame.maxX - swithMarginLeft, height: frame.size.height)
        selectedContentView.center.x = bounds.midX + (switchBtn.frame.maxX + swithMarginLeft)/2
        selectedContentView.center.y = bounds.midY
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
