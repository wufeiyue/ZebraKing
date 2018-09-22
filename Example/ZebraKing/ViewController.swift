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
    
    var dataSource: Array<ProfileModel> = UIApplication.appdelegate?.mockSource ?? Array<ProfileModel>()
    
    var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .white
        
        tableView = UITableView(frame: view.bounds, style: .plain)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableFooterView = UIView()
        view.addSubview(tableView)
        
        guard let sign = dataSource.filter({ $0.identifier == "sign" }).first?.content else {
            return
        }
        
        guard let id = dataSource.filter({ $0.identifier == "chatId" }).first?.content else {
            return
        }
        
        ZebraKing.login(sign: sign, userId: id)
        
        NotificationCenter.default.addObserver(forName: .didRecievedMessage, object: nil, queue: nil) { (notification) in
            self.showToast(message: "即将打开会话页面", completion: { _ in
                self.openChattingViewController(with: notification)
            })

        }
    }
    
    
    func openChattingViewController(with notification: Notification) {
        if let chatNotification = notification.userInfo?["chatNotification"] as? ChatNotification {
            
            ZebraKing.chat(notification: chatNotification) { result in
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
        
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "MainCell")
        }
        
        if indexPath.row == 0 {
            cell?.textLabel?.text = "配置"
        }
        else if indexPath.row == 1 {
            cell?.textLabel?.text = "点击聊天"
        }
        else {
            cell?.textLabel?.text = "修改我的头像"
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0 {
            let profileViewController = ProfileViewController()
            profileViewController.title = "配置"
            profileViewController.dataSource = dataSource
            present(profileViewController, animated: true)
        }
        else if indexPath.row == 1 {
            
            //点击打开聊天页面
            guard let receiveId = dataSource.filter({ $0.identifier == "otherChatId" }).first?.content else {
                return
            }
            
            ZebraKing.chat(id: receiveId) { result in
                switch result {
                case .success(let conversation):
                    let chattingViewController = ChattingViewController(conversation: conversation)
                    let nav = UINavigationController(rootViewController: chattingViewController)
                    self.present(nav, animated: true, completion: nil)
                case .failure(let error):
                    self.showToast(message: error.localizedDescription)
                }
            }
            
        }
        else if indexPath.row == 2 {
            let alertVC = UIAlertController(title: "修改我的头像", message: "将头像地址输入到文本框中", preferredStyle: .alert)
            
            alertVC.addTextField { textField in
                textField.placeholder = "使用自定义图片地址"
            }
            
            alertVC.addAction(UIAlertAction(title: "取消", style: .cancel, handler: nil))
            
            alertVC.addAction(UIAlertAction(title: "自定义", style: .default, handler: { action in
                
                //修改个人头像
                let text = alertVC.textFields?.first?.text ?? ""
                if text.isEmpty == false {
                    IMChatManager.default.userManager.modifySelfFacePath(text)
                }
                
            }))
            
            alertVC.addAction(UIAlertAction(title: "头像1", style: .default, handler: { _ in
                let text = "https://img.alicdn.com/tfs/TB19l4NQpXXXXXnXpXXXXXXXXXX-80-80.png"
                IMChatManager.default.userManager.modifySelfFacePath(text)
            }))
            
            alertVC.addAction(UIAlertAction(title: "头像2", style: .default, handler: { _ in
                let text = "https://img.alicdn.com/tps/i4/TB1FQS3XYPpK1RjSZFFtKa5PpXa.gif"
                IMChatManager.default.userManager.modifySelfFacePath(text)
            }))
            
            present(alertVC, animated: true, completion: nil)
        }
        
    }
}
