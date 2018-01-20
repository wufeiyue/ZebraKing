//
//  CommonSentenceViewController.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/1/20.
//

import UIKit
import SnapKit

class CommonSentenceViewController: UIViewController {
    
    var containerView: IMDriverSentenceContainerView?
    
    /// 留言输入框
    lazy var textView: UITextView = { [unowned self] in
        let view = UITextView()
        view.delegate = self
        view.contentInset = UIEdgeInsets(top: 3, left: 8, bottom: -3, right: -8)
        view.backgroundColor = .white
        view.font = UIFont.systemFont(ofSize: 14)
        return view
    }()
    
    /// 占位字符
    lazy var placeholderLabel: UILabel = {
        let label = UILabel()
        label.textColor = UIColor(hexString:"#999999")
        label.font = UIFont.systemFont(ofSize: 14)
        label.text = "例：我在现代光谷世贸中心，请直接来接我"
        return label
    }()
    
    lazy var inputTextViewTipLabel: EdgeLabel = { [unowned self] in
        let label = EdgeLabel()
        label.inset = CGSize(width: 15, height: 6)
        label.textColor = UIColor(hexString: "#666666")
        label.font = UIFont.systemFont(ofSize: 11)
        label.text = "已输入：0/\(self.charactersCount)字"
        label.alpha = 0
        label.layer.cornerRadius = 9
        label.layer.masksToBounds = true
        label.backgroundColor = UIColor(hexString: "#f2f2f2")
        return label
    }()
    
    private var cofirmBtn: UIButton!
    
    private var charactersCount = 200
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        [textView, placeholderLabel, inputTextViewTipLabel].forEach {
            view.addSubview($0)
        }
    
        let button = UIButton(type: .system)
        button.setTitle("确认", for: .normal)
        button.isEnabled = false
        button.backgroundColor = .themeColor
        button.frame.size = CGSize(width: 50, height: 25)
        button.addTarget(self, action: #selector(confirmBtnDidTapped), for: .touchUpInside)
        button.layer.masksToBounds = true
        button.layer.cornerRadius = 2
        self.cofirmBtn = button
        
        let barButtonItem = UIBarButtonItem(customView: button)
        navigationItem.rightBarButtonItem = barButtonItem
        
        let backButtonItem = UIBarButtonItem(title: "取消", style: .plain, target: self, action: #selector(cancelBtnDidTapped))
        navigationItem.leftBarButtonItem = backButtonItem
        
        textView.snp.makeConstraints { (m) in
            m.left.right.equalToSuperview().inset(6)
            if #available(iOS 11, *) {
                m.top.equalTo(self.view.safeAreaLayoutGuide.snp.top).offset(8)
            }
            else {
                m.top.equalTo(self.topLayoutGuide.snp.bottom).offset(8)
            }
            m.height.equalTo(180)
        }
        
        placeholderLabel.snp.makeConstraints { (m) in
            m.left.equalTo(textView).offset(10)
            m.top.equalTo(textView).offset(10)
        }
        
        inputTextViewTipLabel.snp.makeConstraints { (m) in
            m.right.equalToSuperview().offset(-10)
            if #available(iOS 11.0, *) {
                m.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom)
            } else {
                m.bottom.equalTo(self.bottomLayoutGuide.snp.top)
            }
        }
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        textView.becomeFirstResponder()
        keyboardControl()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        textView.resignFirstResponder()
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name: .UIKeyboardWillHide, object: nil)
    }
    
    @objc
    private func confirmBtnDidTapped() {
        dismiss(animated: true, completion: { [weak self] in
            guard let this = self else { return }
            this.containerView?.commonMessage.dataSource.insert(this.textView.text, at: 0)
            this.containerView?.tableView.reloadData()
        })
    }

    @objc
    private func cancelBtnDidTapped() {
        dismiss(animated: true, completion: nil)
    }
    
    private func keyboardControl() {
        let notfiicationControl = NotificationCenter.default
        
        //键盘即将弹出
        notfiicationControl.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
            self?.keyboardControl(notification, isShowing: true)
        }
        
        //键盘即将要隐藏
        notfiicationControl.addObserver(forName: .UIKeyboardWillHide, object: nil, queue: OperationQueue.main) { [weak self] (notification) in
            self?.keyboardControl(notification, isShowing: true)
        }
        
    }
    
    func keyboardControl(_ notification: Notification, isShowing: Bool) {
        
        guard var userInfo = notification.userInfo else { return }
        let keybroadRect =  (userInfo[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let curve = (userInfo[UIKeyboardAnimationCurveUserInfoKey] as AnyObject).uint32Value
        let convertedFrame = self.view.convert(keybroadRect!, from: nil)
        let heightOffset = self.view.bounds.size.height - convertedFrame.origin.y
        let options = UIViewAnimationOptions(rawValue: UInt(curve!) << 16
            | UIViewAnimationOptions.beginFromCurrentState.rawValue)
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        self.inputTextViewTipLabel.snp.updateConstraints { (m) in
            if #available(iOS 11.0, *) {
                m.bottom.equalTo(self.view.safeAreaLayoutGuide.snp.bottom).offset(-heightOffset - 10)
            } else {
                m.bottom.equalTo(self.bottomLayoutGuide.snp.top).offset(-heightOffset - 10)
            }
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
}


extension CommonSentenceViewController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        if textView.text.characters.count <= 0 {
            self.placeholderLabel.isHidden = false
            self.cofirmBtn.isEnabled = false
        } else {
            self.placeholderLabel.isHidden = true
            self.cofirmBtn.isEnabled = true
            UIView.animate(withDuration: 0.3, animations: {
                self.inputTextViewTipLabel.alpha = 1
            })
        }
        
        //超过300字，提示用户不能再提示
        if textView.text.characters.count >= charactersCount {
            textView.text = textView.text[0..<charactersCount]
        }
        
        inputTextViewTipLabel.text = "已输入：\(textView.text.characters.count)/\(charactersCount)字"
    }
}

extension String {
    
    /// 对 subString 的操作
    ///
    /// - Parameter range: 调用者必须保证 range 没有超出范围, 不然会崩溃
    fileprivate subscript (range: Range<Int>) -> String {
        get {
            if self.isEmpty || self == "" { return "" }
            let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: range.upperBound, limitedBy: self.endIndex)
            return String(self[startIndex..<endIndex!])
        }
        
        set {
            let startIndex = self.index(self.startIndex, offsetBy: range.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: range.upperBound)
            let strRange = Range(startIndex..<endIndex)
            self.replaceSubrange(strRange, with: newValue)
        }
    }
}
