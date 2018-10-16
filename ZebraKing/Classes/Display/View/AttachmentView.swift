//
//  AttachmentView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/27.
//

import Foundation

public struct AttachmentStyle {
    
    /// 是否显示已读未读提示文本
    public var isShowReadLab: Bool = true
    
    /// 配置已读未读的文本
    public var text: String = ""
    
    /// 配置已读未读文本的颜色
    public var textColor: UIColor = .black
    
    /// 配置已读未读文本的font
    public var font: UIFont = .systemFont(ofSize: 12)
    
    /// 发送失败重试的图标
    public var image: UIImage? = MessageStyle.retry.image
    
    public init() { }
}

public struct AttachmentLayout {
    
    //MARK: - 设置已读未读
    
    /* 设置已读未读距离消息框(messageContainerView)的距离, 以右下角为坐标(0,0), 向左向上取正值
     
     ^ +
     |4
     |3
     <--------------|2 消息框
     6   5  4  3  2 1
     
     */
    public var readRect: CGRect = CGRect(x: 5, y: 0, width: 30, height: 16)
    
    public var messageRect: CGRect = CGRect(x: 5, y: 0, width: 20, height: 20)
    
    /// 自身的宽度
    public var width: CGFloat = 36
    
}

extension AttachmentLayout {
    
    func readStatusBounds(super size: CGSize) -> CGRect {
        let point = CGPoint(x: size.width - readRect.origin.x - readRect.size.width, y: size.height - readRect.origin.y - readRect.size.height)
        return CGRect(origin: point, size: readRect.size)
    }
    
    func sendStatusBounds(super size: CGSize) -> CGRect {
        let point = CGPoint(x: size.width - messageRect.origin.x - messageRect.size.width, y: (size.height - messageRect.size.height)/2)
        return CGRect(origin: point, size: messageRect.size)
    }
}

open class AttachmentView: UIView {
    
    public var style: AttachmentStyle!
    public var layout: AttachmentLayout = AttachmentLayout()
    
    /// 已读未读label
    private lazy var readStatusLab: UILabel = {
        $0.textAlignment = .right
        addSubview($0)
        return $0
    }(UILabel())
    
    /// 发送失败
    private lazy var retrySendedBtn: UIButton = {
        $0.imageView?.contentMode = .scaleAspectFit
        addSubview($0)
        return $0
    }(UIButton(type: .custom))
    
    private var messageStatus: MessageStatus? {
        didSet {
            setNeedsLayout()
        }
    }
    
    /// 发送中的状态
    private lazy var indicatorView: UIActivityIndicatorView = {
        addSubview($0)
        return $0
//    }(UIActivityIndicatorView(style: .gray))
    }(UIActivityIndicatorView(activityIndicatorStyle: .gray))
    
    public func displayView(with messageStatus: MessageStatus) {
        
        defer {
            self.messageStatus = messageStatus
        }
        
        switch messageStatus {
        case .sending:
            //为了避免消息刚发出去就加载loading, 显示效果不美观, 这里给个延时操作
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                if .sending == self.messageStatus || .none == self.messageStatus {
                    self.indicatorView.startAnimating()
                }
            }
            readStatusLab.isHidden = true
            retrySendedBtn.isHidden = true
        case .success:
            //消息发送成功
            indicatorView.stopAnimating()
            if style.isShowReadLab {
                readStatusLab.isHidden = false
                readStatusLab.textColor = style.textColor
                readStatusLab.text = style.text
                readStatusLab.font = style.font
            }
            retrySendedBtn.isHidden = true
        case .failure:
            //消息发送失败
            indicatorView.stopAnimating()
            if style.isShowReadLab {
                readStatusLab.isHidden = true
            }
            retrySendedBtn.isHidden = false
            retrySendedBtn.setImage(style.image, for: .normal)
        default:
            break
        }
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if case .some(let status) = messageStatus {
            switch status {
            case .sending:
                indicatorView.center = CGPoint(x: bounds.midX, y: bounds.midY)
            case .success:
                readStatusLab.frame = layout.readStatusBounds(super: bounds.size)
            case .failure:
                retrySendedBtn.frame = layout.sendStatusBounds(super: bounds.size)
            default:
                break
            }
        }
        
    }
    
    open func reset() {
        if indicatorView.isAnimating {
           indicatorView.stopAnimating()
        }
        readStatusLab.text = nil
    }
}

