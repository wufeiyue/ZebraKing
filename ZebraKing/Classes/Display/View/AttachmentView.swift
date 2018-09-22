//
//  AttachmentView.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/27.
//

import Foundation

open class AttachmentView: UIView {
    
    public var text: String? {
        didSet {
            readStatusLab.text = text
            setNeedsLayout()
        }
    }
    
    public var image: UIImage? {
        didSet {
            messageStautsView.image = image
            setNeedsLayout()
        }
    }
    
    public var highlightedImage: UIImage? {
        didSet {
            messageStautsView.highlightedImage = highlightedImage
        }
    }
    
    public var readRect: CGRect = .zero
    public var messageRect: CGRect = .zero
    
    /// 已读未读label
    lazy var readStatusLab: UILabel = {
        let lab = UILabel()
        lab.textAlignment = .right
        addSubview(lab)
        return lab
    }()
    
    /// 发送中/失败
    private lazy var messageStautsView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        addSubview(imageView)
        return imageView
    }()
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        
        if text?.isEmpty == false {
            let point = CGPoint(x: bounds.size.width - readRect.origin.x - readRect.size.width, y: bounds.size.height - readRect.origin.y - readRect.size.height)
            readStatusLab.frame = CGRect(origin: point, size: readRect.size)
        }
        
        if image != nil {
            let point = CGPoint(x: bounds.size.width - messageRect.origin.x - messageRect.size.width, y: (bounds.size.height - messageRect.size.height)/2)
            messageStautsView.frame = CGRect(origin: point, size: messageRect.size)
        }
    }
}
