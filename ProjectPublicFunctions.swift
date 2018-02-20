//
//  ProjectPublicFunctions.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/9/2.
//  Copyright © 2017 David. All rights reserved.
//

import Foundation
import SwiftDate

struct ClassTime {
    var currentDate: DateInRegion
    
    init() {
        self.currentDate = DateInRegion()
    }
    
    var period: [Period] {
        return [Period(start: currentDate.atTime(hour: 8, minute: 0, second: 0)!,
                       end: currentDate.atTime(hour: 8, minute: 42, second: 0)!),
                Period(start: currentDate.atTime(hour: 8, minute: 46, second: 0)!,
                       end: currentDate.atTime(hour: 9, minute: 28, second: 0)!),
                Period(start: currentDate.atTime(hour: 9, minute: 32, second: 0)!,
                       end: currentDate.atTime(hour: 10, minute: 32, second: 0)!),
                Period(start: currentDate.atTime(hour: 10, minute: 42, second: 0)!,
                       end: currentDate.atTime(hour: 11, minute: 24, second: 0)!),
                Period(start: currentDate.atTime(hour: 11, minute: 28, second: 0)!,
                       end: currentDate.atTime(hour: 12, minute: 10, second: 0)!),
                Period(start: currentDate.atTime(hour: 12, minute: 14, second: 0)!,
                       end: currentDate.atTime(hour: 12, minute: 56, second: 0)!),
                Period(start: currentDate.atTime(hour: 13, minute: 0, second: 0)!,
                       end: currentDate.atTime(hour: 13, minute: 38, second: 0)!),
                Period(start: currentDate.atTime(hour: 13, minute: 42, second: 0)!,
                       end: currentDate.atTime(hour: 14, minute: 24, second: 0)!),
                Period(start: currentDate.atTime(hour: 14, minute: 28, second: 0)!,
                       end: currentDate.atTime(hour: 15, minute: 10, second: 0)!)
                ]
    }
}

struct Period {
    var start: DateInRegion
    var end: DateInRegion
    
    init(start: DateInRegion, end: DateInRegion) {
        self.start = start
        self.end = end
    }
}

func periodTimerString(periodNumber: Int) -> String {
    var timerString: String = ""
    let period = ClassTime().period[periodNumber-1]
    let currentTime = DateInRegion()
    print(currentTime)
    
    var difference: TimeInterval? = nil
    
    if currentTime.isBefore(date: period.start, granularity: .second) {
        timerString = "Starts in "
        difference = period.start - currentTime
    } else if currentTime.isBefore(date: period.end, granularity: .second) {
        timerString = "Ends in "
        difference = period.end - currentTime
    } else {
        timerString = "Ended "
        difference = currentTime - period.end
    }
    
    let minutes = Int(difference!).seconds.in(.minute)!
    
    if minutes > 2 {
        timerString += String(describing: minutes) + " minutes"
    } else {
        let seconds = Int(difference!)
        timerString += String(describing: seconds) + " seconds"
    }
    
    return timerString
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
    case 8: return "1:42PM - 2:23PM"
    case 9: return "2:24PM - 3:10PM"
    default: return "Error!"
    }
}

func getCurrentPeriod() -> Int {
    let currentTime = DateInRegion()
    let period = ClassTime().period
    
    switch currentTime {
    case currentTime.startOfDay..<period[0].end:
        return 1
    case period[0].end..<period[1].end:
        return 2
    case period[1].end..<period[2].end:
        return 3
    case period[2].end..<period[3].end:
        return 4
    case period[3].end..<period[4].end:
        return 5
    case period[4].end..<period[5].end:
        return 6
    case period[5].end..<period[6].end:
        return 7
    case period[6].end..<period[7].end:
        return 8
    case period[7].end..<period[8].end:
        return 9
    default:
        return 10
    }
}

func dayCheck() -> String {
    var dayOfSchool: String? = nil
    let date = Date()
    let formatter = DateFormatter()
    let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
    let path = plistPath.appending("/Day.plist")
    guard let dayDict = NSDictionary(contentsOfFile: path) as? [String: String] else {
        return "No School"
    }
    formatter.dateFormat = "yyyyMMdd"
    let checkDate = formatter.string(from: date)
    
    dayOfSchool = dayDict[checkDate] ?? "No School"
    return dayOfSchool!
}

func getClassDataAt(day: String) -> [[String: Any]] {
    let period = getCurrentPeriod()
    var listClasses = [[String: Any]]()

    let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
    let fileName = "/Class" + day + ".plist"
    let path = plistPath.appending(fileName)

    guard let allClasses = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
        return listClasses
    }

    //let lunch = ["className": "Lunch", "roomNumber": "DH/C", "teacher": "", "period": 11] as [String: Any]
    let meetingForWorship = ["className": "Meeting For Worship", "roomNumber": "Meeting House", "teacher": "", "period": 4] as [String: Any]
    
    guard period <= 9 else {
        return listClasses
    }
    
    if allClasses.count > 8 {
        listClasses = Array(allClasses[(period - 1)...8])
    }
    
    if listClasses.count >= 6 {  // Before Meeting For Worship
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE"
        let day = dateFormatter.string(from: Date())
        if day == "Wed" {
            //                currentClass == 1 -> index = 3
            //                currentClass == 2 -> index = 2
            //                currentClass == 3 -> index = 1
            //                currentClass == 4 -> index = 0
            listClasses[4 - period] = meetingForWorship
        }
    }
    
//    if listClasses.count > 2 { //Before lunch
//        listClasses.insert(lunch, at: 7 - period)
//    }
//
//    switch period {
//    case 0...8:
//        if period == 0 {
//            period = 1
//        }
//        listClasses = Array(allClasses[(period - 1)...7])
//
//        if listClasses.count >= 5 {
//            let dateFormatter = DateFormatter()
//            dateFormatter.dateFormat = "EE"
//            let day = dateFormatter.string(from: Date())
//            if day == "Wed" {
////                currentClass == 1 -> index = 3
////                currentClass == 2 -> index = 2
////                currentClass == 3 -> index = 1
////                currentClass == 4 -> index = 0
//                listClasses[4 - period] = meetingForWorship
//            }
//        }
//
//        if listClasses.count > 2 { //Before lunch
//            listClasses.insert(lunch, at: 7 - period)
//        }
//    case 11:
//        // At lunch
//
//        listClasses = Array(allClasses[6...7])
//
//        listClasses.insert(lunch, at: 0)
//    default:
//        listClasses = []
//    }

    return listClasses
}
