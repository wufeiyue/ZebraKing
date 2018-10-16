//
//  ProfileViewController.swift
//  ZebraKing
//
//  Created by eppeo on 2017/10/26.
//  Copyright © 2017年 eppeo. All rights reserved.
//

import UIKit

class ProfileModel {
    let title: String
    let identifier: String
    
    private var _canEdited: Bool?
    private var _content: String?
    
    var content: String {
        
        set {
            guard !newValue.isEmpty else { return }
            _content = newValue
            UserDefaults.standard.set(newValue, forKey: identifier)
            UserDefaults.standard.synchronize()
        }
        
        get {
            
            if let unwrapped = _content {
                return unwrapped
            }
            else {
                return UserDefaults.standard.string(forKey: identifier) ?? ""
            }
        }
    }
    
    var canEdited: Bool {
        set {
            _canEdited = newValue
        }
        get {
            if let unwrapped = _canEdited {
                return unwrapped
            }
            else {
                return content.isEmpty
            }
        }
    }
    
    init(title: String, identifier: String) {
        self.title = title
        self.identifier = identifier
    }
}

protocol ProfileViewControllerDelegate: class {
    func profileViewController(didUpdate index:Int, model: ProfileModel)
}

class ProfileViewController: UIViewController {

    var dataSource: Array<ProfileModel> = UIApplication.appdelegate?.mockSource ?? Array<ProfileModel>()
    weak var delegate: ProfileViewControllerDelegate?
    
    lazy var tableView: UITableView = { [unowned self] in
        let view = UITableView(frame: self.view.bounds, style: .plain)
        view.delegate = self
        view.dataSource = self
        view.separatorInset = .zero
        view.register(ProfileTableViewCell.self, forCellReuseIdentifier: "ProfileTableViewCellKey")
        return view
    }()
    
    private var cellHeightInView: Int = 0
    private var canResignPage: Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(tableView)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(forName: .UIKeyboardWillShow, object: nil, queue: .main) { notification in
            self.keyboardControl(notification)
        }
       
        NotificationCenter.default.addObserver(forName: .UIKeyboardDidHide, object: nil, queue: .main) { _ in
            self.tableView.frame.size.height = self.view.bounds.size.height
        }
        
    }
    
    func keyboardControl(_ notification: Notification) {
        guard let keybroadRect = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? CGRect else { return }
        let convertedFrame = self.view.convert(keybroadRect, from: nil)
        let heightOffset = self.view.bounds.size.height - convertedFrame.origin.y
        
        UIView.animate(withDuration:0.3,
                       animations: {
                        self.view.layoutIfNeeded()
                        //此处处理对话内容的tabView滚动
                        
                        if self.tableView.frame.size.height == self.view.bounds.size.height {
                            self.tableView.frame.size.height -= heightOffset
                        }
                        
        }) { bool in
            
        }
        
    }
    
    
    func makeToast(_ message: String) {
        navigationController?.view.makeToast(message)
    }


}

extension ProfileViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ProfileTableViewCellKey") as! ProfileTableViewCell
        let model = dataSource[indexPath.row]
        cell.inputTextFile.isEnabled = model.canEdited
        cell.confirmBtn.isEnabled = model.canEdited
        cell.inputTextFile.text = model.content
        cell.titleLabel.text = model.title + model.identifier
        cell.confirmBtn.tag = 1000 + indexPath.row
        cell.delegate = self
        cell.contentView.backgroundColor = model.canEdited ? .white : .groupTableViewBackground
        return cell
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 103
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        let model = dataSource[indexPath.row]
        if !model.canEdited  {
            let alertView = UIAlertView(title: "修改参数", message: model.title, delegate: self, cancelButtonTitle: "取消", otherButtonTitles: "确定")
            alertView.alertViewStyle = .plainTextInput
            alertView.tag = 2000 + indexPath.row
            alertView.show()
        }
        
        cellHeightInView = 103 * indexPath.row
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offsetY = scrollView.contentOffset.y
        
        if offsetY > -50 {
            canResignPage = true
        }
        
    }
    
    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        
        if canResignPage {
            
            self.dismiss(animated: true, completion: nil)
            
        }
        
    }
}

extension ProfileViewController: ProfileTableViewCellDelegate {
    func profileTableViewCell(confirmDidTapped sender: UIButton, inputText: String) {
        let index = sender.tag - 1000
        
        let model = dataSource[index]
        
        guard model.content != inputText else {
            makeToast("文本内容没有变化~")
            return
        }
        
        let newModel = ProfileModel(title: model.title, identifier: model.identifier)
        newModel.canEdited = false
        newModel.content = inputText
        dataSource.remove(at: index)
        dataSource.append(newModel)
        tableView.reloadData()
        delegate?.profileViewController(didUpdate: index, model: newModel)
    }
}

extension ProfileViewController: UIAlertViewDelegate {
    func alertView(_ alertView: UIAlertView, clickedButtonAt buttonIndex: Int) {
        let index = alertView.tag - 2000
        if buttonIndex == 1 {
            //确认按钮
            let model = dataSource[index]
            let inputText = alertView.textField(at: 0)?.text ?? ""
            
            guard model.content != inputText else {
                makeToast("文本内容没有变化~")
                return
            }
            
            let newModel = ProfileModel(title: model.title, identifier: model.identifier)
            newModel.canEdited = false
            newModel.content = inputText
            dataSource.remove(at: index)
            dataSource.append(newModel)
            tableView.reloadData()
            delegate?.profileViewController(didUpdate: index, model: newModel)
        }
    }
}

protocol ProfileTableViewCellDelegate: class {
    func profileTableViewCell(confirmDidTapped sender: UIButton, inputText: String)
}

class ProfileTableViewCell: UITableViewCell {
    
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 15)
        label.textColor = UIColor.black
        return label
    }()
    
    lazy var inputTextFile: UITextField = {
        let textFile = UITextField()
        textFile.borderStyle = .roundedRect
        return textFile
    }()
    
    lazy var confirmBtn: UIButton = {
        let btn = UIButton(type:.system)
        btn.setTitle("确认", for: .normal)
        btn.setTitleColor(UIColor.black, for: .normal)
        btn.setTitleColor(UIColor.gray, for: .disabled)
        btn.backgroundColor = UIColor.groupTableViewBackground
        btn.addTarget(self, action: #selector(btnDidTapped(sender:)), for: .touchUpInside)
        return btn
    }()
    
    @objc func btnDidTapped(sender: UIButton) {
        delegate?.profileTableViewCell(confirmDidTapped: sender, inputText: inputTextFile.text ?? "")
    }
    
    weak var delegate: ProfileTableViewCellDelegate?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        [inputTextFile, confirmBtn, titleLabel].forEach{ contentView.addSubview($0) }
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        //contentView height = 88
        titleLabel.frame = CGRect(x: 15, y: 20, width: contentView.bounds.size.width - 30, height: 15)
        inputTextFile.frame = CGRect(x: 15, y: titleLabel.frame.maxY + 10, width: contentView.bounds.size.width - 95, height: 38)
        confirmBtn.frame = CGRect(x: inputTextFile.frame.maxX + 5, y: inputTextFile.frame.origin.y, width: 60, height: 38)
        confirmBtn.backgroundColor = UIColor.groupTableViewBackground
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}


