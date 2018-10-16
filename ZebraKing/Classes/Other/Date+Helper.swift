
//
//  Date+Helper.swift
//  test
//
//  Created by gongjie on 2017/7/18.
//  Copyright © 2017年 gongjie. All rights reserved.
//

import Foundation

extension Date {
    public func getWeek() -> String {
        let myWeekday: Int = Calendar.current.component(.weekday, from: self)
        switch myWeekday {
        case 0:
            return "周日"
        case 1:
            return "周一"
        case 2:
            return "周二"
        case 3:
            return "周三"
        case 4:
            return "周四"
        case 5:
            return "周五"
        case 6:
            return "周六"
        default:
            return "未取到数据"
        }
    }
    
    public var chatTimeToString: String {
        get {
            let calendar = Calendar.current
            let now = Date()
            let nowComponents: DateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: now)
            let targetComponents:DateComponents = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: self)
            
            let year = (nowComponents.year ?? 0) - (targetComponents.year ?? 0)
            let month = (nowComponents.month ?? 0) - (targetComponents.month ?? 0)
            let day = (nowComponents.day ?? 0) - (targetComponents.day ?? 0)
            
            if year != 0 {
                return string(custom: "YYYY年MM月dd日 HH:mm")
            } else {
                if (month > 0 || day > 7) {
                    return string(custom: "MM月dd日 HH:mm")
                } else if (day > 2) {
                    return String(format: "%@ %02d:%02d", getWeek(), targetComponents.hour ?? 0, targetComponents.minute ?? 0)
                } else if (day == 2) {
                    return String(format: "前天 %02d:%02d", targetComponents.hour ?? 0, targetComponents.minute ?? 0)
                } else if (day == 1) {
                    return String(format: "昨天 %02d:%02d", targetComponents.hour ?? 0, targetComponents.minute ?? 0)
                } else if (day == 0){
                    return string(custom: "HH:mm")
                } else {
                    return ""
                }
            }
        }
    }
    
    private func string(custom: String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = custom
        return dateFormatter.string(from: self)
    }
}


