//
//  ToastView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/7/18.
//

import UIKit

public protocol Toastable {
    func showToast(message:String)
}

extension Toastable where Self: UIViewController {
    public func showToast(message: String) {
        view.makeToast(message, duration: 2)
    }
}

extension UIView {
    
    struct ToastKeys {
        static var timer = "com.zebra.timer"
    }
    
    fileprivate func makeToast(_ message: String, duration: TimeInterval) {
        let toastView = toastViewForMessage(message)
        let point = centerPoint(forToast: toastView, inSuperview: self)
        showToast(toastView, duration: duration, point: point)
    }
    
    private func centerPoint(forToast toast: UIView, inSuperview superview: UIView) -> CGPoint {
        let top = superview.csSafeAreaInsets.top + 30
        return CGPoint(x: superview.bounds.size.width / 2.0, y: top + (toast.frame.size.height / 2.0))
    }
    
    private func toastViewForMessage(_ message: String?) -> UIView {
        
        let wrapperView = UIView()
        wrapperView.backgroundColor = .black
        wrapperView.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin, .flexibleTopMargin, .flexibleBottomMargin]
        wrapperView.layer.cornerRadius = 5
        
        let messageLabel = UILabel()
        messageLabel.text = message
        messageLabel.numberOfLines = 1
        messageLabel.font = .systemFont(ofSize: 16)
        messageLabel.textAlignment = .center
        messageLabel.lineBreakMode = .byTruncatingTail;
        messageLabel.textColor = .white
        messageLabel.backgroundColor = UIColor.clear
        
        let verticalPadding: CGFloat = 10
        let horizontalPadding: CGFloat = 10
        
        let maxMessageSize = CGSize(width: self.bounds.size.width, height: self.bounds.size.height)
        let messageSize = messageLabel.sizeThatFits(maxMessageSize)
        let actualWidth = min(messageSize.width, maxMessageSize.width)
        let actualHeight = min(messageSize.height, maxMessageSize.height)
        messageLabel.frame = CGRect(x: horizontalPadding, y: verticalPadding, width: actualWidth, height: actualHeight)
        
        wrapperView.frame = CGRect(x: 0.0, y: 0.0, width: actualWidth + (2 * horizontalPadding), height: actualHeight + (2 * verticalPadding))
        
        wrapperView.addSubview(messageLabel)
        
        return wrapperView
    }
    
    private func showToast(_ toast: UIView, duration: TimeInterval, point: CGPoint) {
        
        toast.center = point
        toast.alpha = 0.0
        
        self.addSubview(toast)
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseOut, .allowUserInteraction], animations: {
            toast.alpha = 1.0
        }) { _ in
            let timer = Timer(timeInterval: duration, target: self, selector: #selector(UIView.toastTimerDidFinish(_:)), userInfo: toast, repeats: false)
            RunLoop.main.add(timer, forMode: RunLoopMode.commonModes)
            objc_setAssociatedObject(toast, &ToastKeys.timer, timer, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
        
    }
    
    @objc
    private func toastTimerDidFinish(_ timer: Timer) {
        guard let toast = timer.userInfo as? UIView else { return }
        hideToast(toast)
    }
    
    private func hideToast(_ toast: UIView) {
        if let timer = objc_getAssociatedObject(toast, &ToastKeys.timer) as? Timer {
            timer.invalidate()
        }
        
        UIView.animate(withDuration: 0.2, delay: 0.0, options: [.curveEaseIn, .beginFromCurrentState], animations: {
            toast.alpha = 0.0
        }) { _ in
            toast.removeFromSuperview()
        }
    }
    
    fileprivate var csSafeAreaInsets: UIEdgeInsets {
        if #available(iOS 11.0, *) {
            return self.safeAreaInsets
        } else {
            return .zero
        }
    }
    
}
