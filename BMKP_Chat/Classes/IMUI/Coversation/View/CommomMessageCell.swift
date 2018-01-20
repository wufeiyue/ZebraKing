//
//  CommomMessageCell.swift
//  Alamofire
//
//  Created by 武飞跃 on 2017/11/21.
//

import UIKit

protocol CommomMessageCellDelegate:class {
    func commomMessageCell(_ cell:CommomMessageCell, didTapped text:String)
}

final class CommomMessageCell: UITableViewCell {
    weak var delegate:CommomMessageCellDelegate?
    var messageLabel: UILabel!
    var iconBtn: UIButton!
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        createView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func createView() {
        messageLabel = UILabel()
        messageLabel.font = UIFont.systemFont(ofSize: 14)
        messageLabel.textColor = UIColor(hexString: "#606060")
        messageLabel.numberOfLines = 1
        messageLabel.textAlignment = .left
        contentView.addSubview(messageLabel)
        
        iconBtn = UIButton()
        iconBtn.setImage(UIImage(named:"commomPlus"), for: .normal)
        iconBtn.imageView?.frame.size = CGSize(width: 16, height: 16)
        iconBtn.addTarget(self, action: #selector(iconBtnDidTapped(sender:)), for: .touchUpInside)
        contentView.addSubview(iconBtn)
        
        contentView.backgroundColor = .clear
        backgroundColor = .clear
    }
    
    @objc private func iconBtnDidTapped(sender: UIButton) {
        delegate?.commomMessageCell(self, didTapped: messageLabel.text ?? "")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        let rect = contentView.bounds
        messageLabel.frame = CGRect(x: 15, y: 0, width: rect.size.width - rect.size.height - 15, height: 18)
        messageLabel.center.y = rect.midY
        iconBtn.frame = CGRect(x: messageLabel.frame.maxX, y: 0, width: rect.size.height, height: rect.size.height)
        iconBtn.center.y = rect.midY
    }
}

