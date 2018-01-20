//
//  ViewController.swift
//  BMChat
//
//  Created by eppeo on 10/27/2017.
//  Copyright (c) 2017 eppeo. All rights reserved.
//

import UIKit
import BMKP_Chat
import BMKP_Network

class ViewController: UIViewController {

    var dataSource = [ProfileModel(title: "用户的账号类型  (String) ", identifier: "accountType"),
                      ProfileModel(title: "用户标识接入SDK的应用ID (Int32) ", identifier: "appid"),
                      ProfileModel(title: "sign (String) ", identifier: "sign"),
                      ProfileModel(title: "IMChat的id (String) ", identifier: "chatId"),
                      ProfileModel(title: "对方的chatId (String) ", identifier: "otherChatId")]
    
    var otherList = ["打开客服页面"]
    
    lazy var tableView: UITableView = { [unowned self] in
        let tab = UITableView.init(frame: self.view.bounds, style: .grouped)
        tab.delegate = self
        tab.dataSource = self
        tab.backgroundColor = UIColor.groupTableViewBackground
        tab.separatorInset = .zero
        return tab
    }()
    
    var taskQueue:TaskQueue!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let item = UIBarButtonItem(title: "配置", style: .done, target: self, action: #selector(profileBtnDidTapped))
        navigationItem.rightBarButtonItem = item
        view.addSubview(tableView)
        start()
        title = "BMCHAT"
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(didRecievedServerMessage), name: .didRecievedServerMessage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRecievedDriverMessage), name: .didRecievedDriverMessage, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(didRecievedPassengerMessage), name: .didRecievedPassengerMessage, object: nil)
        
    }
    
    
    private func start() {
        
        let start = TaskQueueItem(title: "初始化SDK", tips: "") { [weak self] () -> Bool in
            guard let this = self else {
                return false
            }
            
            guard let accountType = this.dataSource.filter({ $0.identifier == "accountType" }).first?.content,
                let appid = this.dataSource.filter({ $0.identifier == "appid" }).first?.content
                else {
//                    Hud.show(.error("还有参数没配置"))
                    return false
            }
            
            if accountType.isEmpty {
//                Hud.show(.error("accountType 不能为空"))
                return false
            }
            
            if appid.isEmpty {
//                Hud.show(.error("appid 不能为空"))
                return false
            }
            
            let configuation = IMConfiguation(accountType: accountType,
                                              appid: appid)
            configuation.disableLog = true
            IMChatManager.default.register(configuration: configuation)
            
            return true
            
        }
        
        let login = TaskQueueItem(title: "登录IM", tips: "") { [weak self] () -> Bool in
            guard let this = self else {
                return false
            }
            
            guard let sign = this.dataSource.filter({ $0.identifier == "sign" }).first?.content,
                let chatId = this.dataSource.filter({ $0.identifier == "chatId" }).first?.content else {
//                    Hud.show(.error("还有参数没配置"))
                    return false
            }
            
            if sign.isEmpty {
//                Hud.show(.error("sign 为配置"))
                return false
            }
            
            if chatId.isEmpty {
//                Hud.show(.error("我的chatId 为空"))
                return false
            }
            
            IMChatManager.default.login(sign: sign, userId: chatId, successCompletion: {
//                Hud.show(.error("登录成功了"))
            }, failCompletion: { (code, str) in
//                Hud.show(.error("登录失败了"))
            })
            
            return true
            
        }
        
        let open = TaskQueueItem(title: "打开会话页面", tips: "可重复打开") { [weak self] () -> Bool in
            guard let this = self, let chatId = this.dataSource.filter({ $0.identifier == "otherChatId" }).first?.content else {
//                Hud.show(.error("还有参数没配置"))
                return false
            }
            
            if chatId.isEmpty {
//                Hud.show(.error("对方chatId 为空"))
                return false
            }
            
            if let unit = IMChatUnit(id: chatId) {
                
                let chatting = IMChatViewController()
//                IMChatManager.default.host.role = .server
                IMChatManager.default.present(chatUnit: unit, target: nil, chatVC: chatting, chatTitle: "", completion: nil)
                
                return true
            }
            
            return false
        }
        
        let openServer = TaskQueueItem(title: "打开客服页面", tips: "可重复打开") { () -> Bool in
//            IMChatManager.default.host?.role = .driver
            let chatting = IMChatViewController()
            chatting.receiver = .server
            chatting.delegate = self
//            self.bk.presentNaviController(root: chatting)
            return false
        }
        
        taskQueue = TaskQueue(queue: [start, login, open])
        taskQueue.addParallel([openServer], nextStartExecuted: login)
        taskQueue.result = { [unowned self] in
            self.tableView.reloadData()
        }
        taskQueue.isRetryLast = true
        taskQueue.start()
        
    }
    
    
    //跳转到配置页面
    @objc func profileBtnDidTapped() {
        let profileVC = ProfileViewController()
        profileVC.dataSource = dataSource
        profileVC.delegate = self
        profileVC.title = "配置"
        navigationController?.pushViewController(profileVC, animated: true)
    }

    @objc func didRecievedServerMessage() {
        
    }
    
    @objc func didRecievedDriverMessage() {
        
    }
    
    @objc func didRecievedPassengerMessage() {
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

extension ViewController: IMChatViewControllerDelegate {
    func chatViewController(_ viewController: IMChatViewController, firstRequestNetworkDidLoadData receiver: IMUserUnit) -> DefaultRequest? {
        return nil
    }
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        var cell = tableView.dequeueReusableCell(withIdentifier: "Key") as? MainCell
        if cell == nil {
            cell = MainCell(style: .value1, reuseIdentifier: "Key")
        }
        
        if indexPath.section == 0 {
            
            let model = taskQueue.queue[indexPath.row]
            cell?.titleLabel.text = model.title
            cell?.subTitleLabel.text = model.tips
            
            var value: UIImage? {
                switch taskQueue.isExecuted(at: indexPath.row) {
                case .success:
                    return UIImage(named:"b_right")
                case .faliure:
                    return UIImage(named:"b_wrong")
                case .normal:
                    return nil
                }
            }
            cell?.iconView.image = value
            return cell!
        }
        else {
            let model = taskQueue.parallel[indexPath.row]
            cell?.titleLabel.text = model.title
            cell?.subTitleLabel.text = model.tips
            return cell!
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return taskQueue.queue.count
        }
        else {
            return taskQueue.parallel.count
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 55.0
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        taskQueue.execute(at: indexPath.row, section: indexPath.section)
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "串行"
        }
        return "并行"
    }
}

extension ViewController: ProfileViewControllerDelegate {
    func profileViewController(didUpdate index: Int, model: ProfileModel) {
        dataSource[index] = model
    }
}

class MainCell: UITableViewCell {
    var iconView: UIImageView!
    var titleLabel: UILabel!
    var subTitleLabel: UILabel!
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        
        iconView = UIImageView()
        iconView.contentMode = .scaleAspectFit
        contentView.addSubview(iconView)
        
        titleLabel = UILabel()
        titleLabel.textColor = .black
        titleLabel.font = UIFont.systemFont(ofSize: 15)
        contentView.addSubview(titleLabel)
        
        subTitleLabel = UILabel()
        subTitleLabel.textColor = .red
        subTitleLabel.font = UIFont.systemFont(ofSize: 12)
        contentView.addSubview(subTitleLabel)
        
        backgroundColor = UIColor.groupTableViewBackground
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        titleLabel.frame = CGRect(x: 15, y: 0, width: 0, height: 0)
        titleLabel.sizeToFit()
        titleLabel.center.y = contentView.bounds.midY
        subTitleLabel.frame = CGRect(x: titleLabel.frame.maxX + 2, y: titleLabel.frame.maxY - 16, width: 80, height: 14)
        iconView.frame = CGRect(x: contentView.bounds.size.width - 45, y: 0, width: 20, height: 20)
        iconView.center.y = contentView.bounds.midY
    }
}


