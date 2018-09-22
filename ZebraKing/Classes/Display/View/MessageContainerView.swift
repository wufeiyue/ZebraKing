//
//  MessageContainerView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/27.
//

import Foundation

open class MessageContainerView: UIImageView {
    
    private let imageMask = UIImageView()
    
    private let animationKey = "MessageContainerView-Opacity"
    
    open override var frame: CGRect {
        didSet {
            //            imageMask.frame = bounds
        }
    }
    
    /// 为视图自身添加一个透明度渐变的动画效果
    open func addAnimation() {
        let anim = CABasicAnimation(keyPath: "opacity")
        anim.duration = 1
        anim.fromValue = 1
        anim.toValue = 0.6
        anim.repeatCount = HUGE
        anim.autoreverses = true
        layer.add(anim, forKey: animationKey)
    }
    
    /// 移除透明度渐变的动画
    open func removeAnimation() {
        layer.removeAnimation(forKey: animationKey)
    }
    
}
