//
//  IMChatViewController+CellHandle.swift
//  BMKP
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import UIKit

extension IMMessageType {
    
    func chatCellHeight(_ model: IMMessage) -> CGFloat {
        switch self {
        case .text:
            return IMTextCell.layoutHeight(model)
            
        case .sound:
            return IMAudioCell.layoutHeight(model)
        
        case .timeTip:
            return IMTimeTipCell.layoutHeight(model)
            
        case .saftyTip:
            return IMTextCell.layoutHeight(model)
            
        default:
            return 0
        }
    }

    
    
    func chatCell(_ tableView: UITableView, indexPath: IndexPath, model: IMMessage, receiver: IMUserUnit, viewController: IMChatViewController) -> UITableViewCell {
        switch self {
        case .text:
            
            let cell: IMTextCell = tableView.dequeueReusableCell(withIdentifier: "IMTextCellKey") as! IMTextCell
            cell.configContentView(model, receiver: receiver)
            cell.delegate = viewController
            return cell
            
        case .sound:
            let cell: IMAudioCell = tableView.dequeueReusableCell(withIdentifier: "IMAudioCellKey") as! IMAudioCell
            cell.configContentView(model, receiver: receiver)
            cell.delegate = viewController
            return cell
        
        case .timeTip:
            let cell: IMTimeTipCell = tableView.dequeueReusableCell(withIdentifier: "IMTimeTipCellKey") as! IMTimeTipCell
            cell.configContentView(model, receiver: receiver)
            cell.delegate = viewController
            return cell
            
        case .saftyTip:
            let cell: IMTextCell = tableView.dequeueReusableCell(withIdentifier: "IMTextCellKey") as! IMTextCell
            cell.configContentView(model, receiver: receiver)
            cell.delegate = viewController
            return cell
            
        default:
            return UITableViewCell()
        }
    }

}
