//
//  IMChatActionBarSwitchContainerView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2017/12/13.
//

import UIKit

public final class IMChatActionBarSwitchContainerView: UIView {

    public var switchBtnStatus: IMChatActionBarControlState = .selected
    public weak var delegate: IMChatActionBarContainerViewDelegate?
    private var switchBtn: UIButton!
    private var normalContentView: UIView!
    private var selectedContentView: UIView!
    let swithMarginLeft: CGFloat = 10
    let switchMarginBottom: CGFloat = 8.5
    let swithWidthAndHeight: CGFloat = 33

    public init(normal: IMChatActionBarContainerViewModel, selected: IMChatActionBarContainerViewModel) {
        super.init(frame: .zero)
        
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
        
        switchBtn.snp.makeConstraints { (m) in
            m.left.equalTo(swithMarginLeft)
            m.bottom.equalTo(-switchMarginBottom)
            m.size.equalTo(CGSize(width: swithWidthAndHeight, height: swithWidthAndHeight))
        }
        
        normalContentView.snp.makeConstraints { (m) in
            m.top.bottom.right.equalToSuperview()
            m.left.equalTo(switchBtn.snp.right).offset(swithMarginLeft)
        }
        
        selectedContentView.snp.makeConstraints { (m) in
            m.edges.equalTo(normalContentView)
        }

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
    private func switchBtnDidTapped(_ sender: UIButton) {
        
        delegate?.chatActionBarContainerView(self, btnStatus: switchBtnStatus)
        
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
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
