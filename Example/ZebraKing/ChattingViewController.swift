//
//  ChattingViewController.swift
//  ZebraKing_Example
//
//  Created by 武飞跃 on 2018/9/22.
//  Copyright © 2018年 CocoaPods. All rights reserved.
//
import UIKit
import ZebraKing

class ChattingViewController: CommonConversationViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let item = UIBarButtonItem(title: "退出", style: .done, target: self, action: #selector(profileBtnDidTapped))
        navigationItem.rightBarButtonItem = item
        
    }
    
    @objc
    private func profileBtnDidTapped() {
        dismiss(animated: true, completion: nil)
    }
    
}
