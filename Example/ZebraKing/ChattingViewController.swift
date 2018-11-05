//
//  ChattingViewController.swift
//  ZebraKing_Example
//
//  Created by 武飞跃 on 2018/9/22.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//
import UIKit
import ZebraKing

class ChattingViewController: ConversationViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let item = UIBarButtonItem(title: "退出", style: .done, target: self, action: #selector(profileBtnDidTapped))
        navigationItem.rightBarButtonItem = item
        
    }
    
    @objc
    private func profileBtnDidTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    open override func showToast(message: String) {
        self.toast_showToast(message: message)
    }
}
