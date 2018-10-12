//
//  UIViewController+Toast.swift
//  ZebraKing
//
//  Created by eppeo on 2018/3/8.
//  Copyright © 2018年 eppeo. All rights reserved.
//

import Foundation
import Toast_Swift

protocol Toastable {
    func showToast(message: String, completion: ((_ didTap: Bool) -> Void)?)
    func showCenterToast(message: String)
}

extension Toastable where Self: UIViewController {
    func showToast(message: String, completion: ((_ didTap: Bool) -> Void)? = nil) {
        view.makeToast(message, duration: 2, position: .center, title: nil, image: nil, style: ToastManager.shared.style, completion: completion)
    }
    
    func showCenterToast(message: String) {
        view.makeToast(message, duration: 1.5, position: ToastPosition.center, title: nil, image: nil, style: .init(), completion: nil)
    }
    
}

extension UIViewController: Toastable{ }
