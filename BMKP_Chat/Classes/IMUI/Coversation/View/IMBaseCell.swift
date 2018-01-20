//
//  IMBaseCell.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import UIKit
import Kingfisher

private let kChatNicknameLabelHeight: CGFloat = 20 // 昵称的高度

public class IMBaseCell: UITableViewCell {
    
    var msgModel: IMMessage?
    weak var delegate: IMChatCellEventDelegate?
    
    //已读未读状态
    lazy var readStatusLab: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.bounds = CGRect(x: 0, y: 0, width: 29, height: 17)
        return label
    }()
    
    //正在发送中...
    lazy var activityView: UIActivityIndicatorView = {
        let view = UIActivityIndicatorView()
        view.isHidden = true
        return view
    }()
    
    //重试按钮
    lazy var retryButton: UIButton = { [unowned self] in
        let btn = UIButton(type: .system)
        btn.isHidden = true
        btn.addTarget(self, action: #selector(retrySendMsg), for: .touchUpInside)
        return btn
    }()
    
    //用户头像
    private lazy var userPic: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = .clear
        imageView.frame.size = CGSize(width: kUserPicWidth, height: kUserPicWidth)
        imageView.frame.origin.y = 0
        return imageView
    }()
    
    //用户昵称
    private lazy var nickNameLab: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 11)
        label.textColor = .darkGray
        return label
    }()
    
    
    @objc func retrySendMsg() {
        if let delegate = delegate {
            delegate.cellDidTapedRetry(msg: msgModel)
        }
    }
    
    
    override public init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        createView()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func createView() {
        selectionStyle = .none
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        [readStatusLab, userPic, nickNameLab, activityView, retryButton].forEach{ contentView.addSubview($0) }
    }
    
    private func imUserIcon(id: String) -> String {
        return "com.bmkp.imUserIcon." + id
    }
    
    func configContentView(_ model: IMMessage, receiver: IMUserUnit) {

        if model.isMineMsg {
            //获取本机登录用户对象, 程序走到这里本机用户的角色一定是可以确认的, 理论上不存在 host == nil, 除非本机用户 userId前缀不符合IMChatRole.convert规则
            if let host = IMChatManager.default.host {
                userPic.setImage(uri: host.model.facePath, placeholder: UIImage(named: host.role.imageName), cornerRadius: 2)
            }
        }
        else {
            if .server == receiver.role {
                self.userPic.image = UIImage(named: receiver.role.imageName)
            }
            else {
//                setUserPicWithUser(user: receiver)
                userPic.setImage(uri: receiver.model.facePath?.qiNiuHttpsUrl, placeholder: UIImage(named: receiver.role.imageName), cornerRadius: 2)

            }
        }
        self.readStatusLab.text = (model.isRead ? "已读" : "未读")
        self.readStatusLab.textColor = (model.isRead ? UIColor.lightGray : UIColor.orange)
        self.nickNameLab.text = receiver.model.nickName
    }
    
    private func setUserPicWithUser(user: IMUserUnit) {
        let key = imUserIcon(id: user.model.id)
        KingfisherManager.shared.cache.retrieveImage(forKey: key, options: nil, completionHandler: { [weak self] (image, _) in
            
            guard let this = self else { return }
            
            if let image = image {
                this.userPic.image = image
            }
            else {
                guard let urlStr = user.model.facePath?.qiNiuHttpsUrl,
                    let url = URL(string: urlStr) else {
                    this.userPic.image = UIImage(named: user.role.imageName)
                    return
                }
                KingfisherManager.shared.downloader.downloadImage(with: url, retrieveImageTask: nil, options: nil, progressBlock: nil, completionHandler: { [weak self] (image, _, _, _) in
                    
                    guard let this = self else { return }
                    
                    if let image = image {
                        KingfisherManager.shared.cache.store(image, forKey: key)
                        this.userPic.image = image
                    }
                    else {
                        this.userPic.image = UIImage(named: user.role.imageName)
                    }
                })
            }
        })
    }
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        guard let model = self.msgModel else {
            return
        }
        if model.isMineMsg {
            nickNameLab.frame.size.height = 0
            userPic.frame.origin.x = UIScreen.main.bounds.size.width - kUserPicMarginLeading - kUserPicMarginTralling - kUserPicWidth
        } else{
            nickNameLab.frame.size.height = 0
            userPic.frame.origin.x = kUserPicMarginLeading
        }
    }
    
}

public typealias ImageDownloadProgressBlock = (_ receivedSize: Int64, _ totalSize: Int64) -> Void
public typealias ImageRequestCompletionHandler = (_ image: UIImage?, _ error: NSError?, _ imageURL: URL?) -> Void

extension UIImageView {
    
    fileprivate func setImage(uri: String?, placeholder: UIImage? = nil, cornerRadius: CGFloat = 0) {
        
        var options: [KingfisherOptionsInfoItem] = []
        
        if cornerRadius > 0 {
            options.append(.processor(RoundCornerImageProcessor.init(cornerRadius: cornerRadius)))
        }
        
        self.setImage(url: uri.flatMap(URL.init(string:)), placeholder: placeholder, options: options, progress: nil, completion: nil)
    }
    
    fileprivate  func setImage(url: URL?, placeholder: UIImage? = nil, options: [KingfisherOptionsInfoItem] = [], progress: ImageDownloadProgressBlock? = nil, completion: ImageRequestCompletionHandler? = nil) {
        
        let containFade = options.contains(where: {
            switch $0 {
            case .transition(let type):
                if case .fade = type {
                    return true
                } else {
                    return false
                }
            default:
                return false
            }
        })
        
        var options = options
        
        if !containFade {
            options.append(.transition(.fade(0.3)))
        }
        
        self.kf.setImage(
            with: url,
            placeholder: placeholder,
            options: options,
            progressBlock: { (receivedSize, totalSize) in
                progress?(receivedSize, totalSize)
        }) { (image, error, _, imageURL) in
            completion?(image, error, imageURL)
        }
        
    }
    
}
