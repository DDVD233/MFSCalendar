//
//  ProjectPublicFunctions.swift
//  MFSCalendar
//
//  Created by David on 2017/9/2.
//  Copyright © 2017年 David. All rights reserved.
//
//  Hard code 一时爽，代码重构火葬场。 --戴维于2019年1月15日

import Foundation
import SwiftDate

var school: School {
    get {
        return MFS()
    }
}

func getMeetTime(period: Int) -> String {
    switch period {
    case 1: return "8:00AM - 8:42AM"
    case 2: return "8:46AM - 9:28AM"
    case 3: return "9:32AM - 10:32AM"
    case 4: return "10:42AM - 11:24AM"
    case 5: return "11:28AM - 12:10AM"
    case 6: return "12:14PM - 12:56PM"
    case 7: return "1:00PM - 1:38PM"
    case 8: return "1:42PM - 2:24PM"
    case 9: return "2:28PM - 3:10PM"
    default: return "Error!"
    }
}
