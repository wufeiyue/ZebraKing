//
//  ViewController.swift
//  ZebraKing
//
//  Created by eppeo on 09/22/2018.
//  Copyright (c) 2018 eppeo. All rights reserved.
//

import UIKit
import ZebraKing

extension UIApplication {
    static var appdelegate: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }
}

class ViewController: UIViewController {
    
    var mockSource: Array<ProfileModel> = UIApplication.appdelegate?.mockSource ?? Array<ProfileModel>()
    
    var dataSource = Array<ChatNotification>()
    
    var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        tableView = UITableView(frame: view.bounds, style: .grouped)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "MenuCell", bundle: nil), forCellReuseIdentifier: "MenuCellKey")
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        
        guard let sign = mockSource.filter({ $0.identifier == "sign" }).first?.content else {
            return
        }
        
        guard let id = mockSource.filter({ $0.identifier == "chatId" }).first?.content else {
            return
        }
        
        ZebraKing.login(sign: sign, userId: id)
        
        NotificationCenter.default.addObserver(forName: .didRecievedMessage, object: nil, queue: nil) { (notification) in
            
            guard let chatNotification = notification.userInfo?["chatNotification"] as? ChatNotification else { return }
            
            self.dataSource.append(chatNotification)
            
            self.tableView.reloadData()

        }
        
    }
    
    func openChattingViewController(with notification: ChatNotification) {
        ZebraKing.chat(notification: notification) { result in
            switch result {
            case .success(let conversation):
                let chattingViewController = ChattingViewController(conversation: conversation)
                let nav = UINavigationController(rootViewController: chattingViewController)
                self.present(nav, animated: true, completion: nil)
            case .failure(_):
                break
            }
        }
    }
    
    //弹框修改个人资料
    private func alertUpdateHostProfile() {
        
        let alertVC = UIAlertController(title: "修改我的头像", message: "将头像地址输入到文本框中", preferredStyle: .alert)
        
        alertVC.addTextField { textField in
            textField.placeholder = "使用自定义图片地址"
        }
        
        alertVC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
        
        alertVC.addAction(UIAlertAction(title: "自定义", style: .default, handler: { action in
            
            //修改个人头像
            let text = alertVC.textFields?.first?.text ?? ""
            if text.isEmpty == false {
                ZebraKing.modifySelfFacePath(path: text)
            }
            
        }))
        
        alertVC.addAction(UIAlertAction(title: "头像1", style: .default, handler: { _ in
            let text = "https://img.alicdn.com/tfs/TB19l4NQpXXXXXnXpXXXXXXXXXX-80-80.png"
            ZebraKing.modifySelfFacePath(path: text)
        }))
        
        alertVC.addAction(UIAlertAction(title: "头像2", style: .default, handler: { _ in
            let text = "https://img.alicdn.com/tps/i4/TB1FQS3XYPpK1RjSZFFtKa5PpXa.gif"
            ZebraKing.modifySelfFacePath(path: text)
        }))
        
        present(alertVC, animated: true, completion: nil)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        NotificationCenter.default.removeObserver(self, name: .didRecievedMessage, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}

extension ViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "MainCell")
        
        if indexPath.section == 0 {
            
            if cell == nil {
                cell = UITableViewCell(style: .subtitle, reuseIdentifier: "MainCell")
                cell?.detailTextLabel?.textColor = .gray
            }
            
            if indexPath.row == 0 {
                cell?.textLabel?.text = "配置"
                cell?.detailTextLabel?.text = "完成基本数据配置才可进行聊天"
            }
            else if indexPath.row == 1 {
                cell?.textLabel?.text = "点击聊天"
                cell?.detailTextLabel?.text = "如果已完成配置, 下次可直接点击这里"
            }
            else {
                cell?.textLabel?.text = "修改我的头像"
                cell?.detailTextLabel?.text = "确保在配置完成以后,再来操作"
            }
            
            return cell!
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "MenuCellKey") as! MenuCell
            cell.delegate = self
            cell.message = dataSource[indexPath.row].content ?? ""
            return cell
        }
        
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 3
        }
        else {
            return dataSource.count
        }
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 {
            return 55
        }
        else {
            return 70
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10.0
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.row == 0 {
            let profileViewController = ProfileViewController()
            profileViewController.title = "配置"
            profileViewController.dataSource = mockSource
            present(profileViewController, animated: true)
        }
        else if indexPath.row == 1 {
            
            //点击打开聊天页面
            guard let receiveId = mockSource.filter({ $0.identifier == "otherChatId" }).first?.content else {
                return
            }
            
            ZebraKing.chat(id: receiveId) { result in
                switch result {
                case .success(let conversation):
                    
                    conversation.host.placeholder = UIImage(named: "chat_header-passenter")
                    conversation.receiver.placeholder = UIImage(named: "chat_header-driver")
                    
                    let chattingViewController = ChattingViewController(conversation: conversation)
                    let nav = UINavigationController(rootViewController: chattingViewController)
                    self.present(nav, animated: true, completion: nil)
                    
                case .failure(let error):
                    self.showToast(message: error.localizedDescription)
                }
            }
            
        }
        else if indexPath.row == 2 {
            alertUpdateHostProfile()
        }
        
    }
}


extension ViewController: MenuCellDelegate {
    
    func confirmBtnDidTapped(_ cell: MenuCell) {
        
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        openChattingViewController(with: dataSource[index])
        
        dataSource.removeAll()
        tableView.reloadData()
    }
    
    func cancelBtnDidTapped(_ cell: MenuCell) {
        guard let index = tableView.indexPath(for: cell)?.row else { return }
        dataSource.remove(at: index)
        tableView.reloadData()
    }
    
}
