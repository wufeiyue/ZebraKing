//
//  TimestampCell.swift
//  Alamofire
//
//  Created by 武飞跃 on 2018/6/27.
//

import Foundation

open class TimestampCell: UICollectionViewCell {
    
    private var timeLabel: UILabel!
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupSubViews()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupSubViews() {
        timeLabel = UILabel()
        timeLabel.textAlignment = .center
        timeLabel.textColor = .lightGray
        timeLabel.font = UIFont.systemFont(ofSize: 13)
        contentView.addSubview(timeLabel)
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        timeLabel.frame = bounds
    }
    
    open func configure(with message: MessageType, at indexPath: IndexPath, and messageCollectionView: MessagesCollectionView) {
        if case .timestamp(let date) = message.data {
            timeLabel.text = date.chatTimeToString
        }
    }
}
