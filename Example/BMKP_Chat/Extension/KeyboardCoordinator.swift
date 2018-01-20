//
//  KeyboardCoordinator.swift
//  BMKP
//
//  Created by ZeroJianMBP on 2017/3/22.
//  Copyright © 2017年 bmkp. All rights reserved.
//

import UIKit


protocol KeyboardObserverDelegate {
	
	var keyboardCoordinator: KeyboardCoordinator? { get }
}


class KeyboardCoordinator: NSObject {

	weak var targetView: UIView?
	
	/// 键盘动画中闭包 
	/// Bool: true 显示时 false 隐藏时
	/// CGFloat: 键盘高度
	var keyboardAction: ((Bool,CGFloat?) -> Void)?
    /// 视图移动高度
    var viewMoveHeight: CGFloat?
	/// 键盘弹出面积
	private(set) var keyboardRect: CGRect?
	/// 键盘动画时间
	private(set) var keyboardAnimationDuration: Double?
    
    private var deinitAction: (() -> Void)?
	
	/// 初始化
	///
	/// - Parameter targetView: 根据键盘移动 Y 坐标的视图
	init(targetView: UIView? = nil) {
		super.init()
		self.targetView = targetView
		observerKeyboard()
	}
    
    deinit {
        deinitAction?()
    }
	
	func observerKeyboard() {
		
		let showObserver = NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: OperationQueue.main) { [weak self](notification) in
			guard
				let userInfo = notification.userInfo,
				let endKeyboardRect = userInfo[UIKeyboardFrameEndUserInfoKey] as? CGRect,
				let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double
				else { return }
			self?.keyboardRect = endKeyboardRect
			self?.keyboardAnimationDuration = duration
			
			if self?.viewMoveHeight == nil {
				self?.viewMoveHeight = endKeyboardRect.origin.y
			}
			
			if let viewMoveHeight = self?.viewMoveHeight, viewMoveHeight > endKeyboardRect.origin.y {
				self?.viewMoveHeight = endKeyboardRect.origin.y
				self?.targetView?.transform = CGAffineTransform.identity
			}
			
			UIView.animate(withDuration: duration, animations: {
				self?.keyboardAction?(true, self?.viewMoveHeight)
				self?.transformTargetView(self?.viewMoveHeight)
			})
			
		}
		
		let hideObserver = NotificationCenter.default.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: OperationQueue.main) { [weak self](notification) in
			guard
				let userInfo = notification.userInfo,
				let duration = userInfo[UIKeyboardAnimationDurationUserInfoKey] as? Double
				else { return }
			
			
			UIView.animate(withDuration: duration, animations: {
				self?.keyboardAction?(false, 0)
				self?.targetView?.transform = CGAffineTransform.identity
			})
		}
        
        deinitAction = {
            NotificationCenter.default.removeObserver(showObserver)
            NotificationCenter.default.removeObserver(hideObserver)
        }
	}
	
	func transformTargetView(_ keyboardHeight: CGFloat?) {
		guard
			let targetView = targetView,
            let keyboardHeight = keyboardHeight,
			let frame = targetView.superview?.convert(targetView.frame, to: targetView.superview)
		else { return }

		let offset = frame.maxY + 10 - keyboardHeight
		if offset > 0 {
			self.targetView?.transform.ty = -offset
		}
	}
	
}
