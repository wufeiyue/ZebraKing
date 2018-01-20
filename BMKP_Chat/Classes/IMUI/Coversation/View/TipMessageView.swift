//
//  TipMessageView.swift
//  test
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import UIKit

class TipMessageView: UIView {
    
    /// 标题
    lazy var titleLab: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hexString: "#333333")
        return label
    }()
    /// 取消按钮
    lazy var cancelButton: UIButton = {
        let btn = UIButton()
        btn.layer.borderWidth = 0.5
        btn.layer.cornerRadius = 3.0
        btn.layer.masksToBounds = true
        btn.layer.borderColor = UIColor(hexString: "#d6d6d6").cgColor
        btn.setTitle("取消", for: .normal)
        btn.backgroundColor = .white
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        btn.setTitleColor(UIColor(hexString:"#333333"), for: .normal)
        return btn
    }()
    
    /// 确定按钮
    lazy var confirmButton: UIButton = {
        let btn = UIButton()
        btn.layer.cornerRadius = 3.0
        btn.layer.masksToBounds = true
        btn.setTitle("确定", for: .normal)
        btn.setTitleColor(.white, for: .normal)
        btn.backgroundColor = UIColor(hexString:"#333333")
        btn.titleLabel?.font = UIFont.systemFont(ofSize: 17)
        return btn
    }()
    
    /// 留言输入框
    lazy var textView: UITextView = { [unowned self] in
        let view = UITextView()
        view.layer.borderWidth = 0.5
        view.layer.cornerRadius = 3.0
        view.layer.masksToBounds = true
        view.layer.borderColor = UIColor(hexString: "#d6d6d6").cgColor
        view.delegate = self
        return view
    }()
    
    /// 占位字符
    lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hexString:"#999999")
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    /// 最后取的输入的文字
    var messageText: String {
        get {
            if textView.text.isEmpty {
                return self.placeholderLabel.text!
            } else {
                
                return  self.textView.text
            }
        }
    }
    
    
    // 初始化视图
    func setupView() {
        [titleLab, cancelButton, confirmButton, textView, placeholderLabel].forEach{ addSubview($0) }
        
        titleLab.snp.makeConstraints { (m) in
            m.left.top.equalTo(22)
            m.height.equalTo(21)
        }
        
        textView.snp.makeConstraints { (m) in
            m.left.right.equalToSuperview().inset(20)
            m.top.equalTo(titleLab.snp.bottom).offset(18)
        }
        
        cancelButton.snp.makeConstraints { (m) in
            m.left.equalTo(textView)
            m.top.equalTo(textView.snp.bottom).offset(14)
            m.height.equalTo(45)
            m.bottom.equalToSuperview().offset(-14)
        }
        
        confirmButton.snp.makeConstraints { (m) in
            m.right.equalTo(textView)
            m.top.equalTo(textView.snp.bottom).offset(14)
            m.width.equalTo(cancelButton)
            m.height.equalTo(45)
            m.left.equalTo(cancelButton.snp.right).offset(6)
        }
        
        placeholderLabel.snp.makeConstraints { (m) in
            m.left.right.equalToSuperview().inset(28)
            m.top.equalTo(titleLab.snp.bottom).offset(25)
        }
        
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}


extension TipMessageView: UITextViewDelegate {
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {//判断输入的字是否是回车，即按下return
            textView.endEditing(true)
            return false
        }
        return true
    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.characters.count <= 0 {
            self.placeholderLabel.isHidden = false
        } else {
            self.placeholderLabel.isHidden = true
        }
        
    }
    
}
