//
//  MenuCell.swift
//  ZebraKing_Example
//
//  Created by 武飞跃 on 2018/10/10.
//  Copyright © 2018 CocoaPods. All rights reserved.
//

import UIKit

protocol MenuCellDelegate: class {
    func confirmBtnDidTapped(_ cell: MenuCell)
    func cancelBtnDidTapped(_ cell: MenuCell)
}

class MenuCell: UITableViewCell {
    
    weak var delegate: MenuCellDelegate?
    
    var message: String = "" {
        didSet {
            contentLabel.text = message
        }
    }
    
    @IBOutlet weak var contentLabel: UILabel!
    
    @IBAction func confirmBtnAction(_ sender: Any) {
        delegate?.confirmBtnDidTapped(self)
    }
    
    @IBAction func cancelBtnAction(_ sender: Any) {
        delegate?.cancelBtnDidTapped(self)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
