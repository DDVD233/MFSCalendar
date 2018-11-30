//
//  ProjectPublicFunctions.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/9/2.
//  Copyright © 2017年 David. All rights reserved.
//

import Foundation
import SwiftDate

struct ClassTime {
    var currentDate: DateInRegion
    
    init() {
        SwiftDate.defaultRegion = Region.local
        self.currentDate = DateInRegion()
    }
    
    var period: [Period] {
        return [Period(start: currentDate.dateBySet(hour: 8, min: 0, secs: 0)!,
                       end: currentDate.dateBySet(hour: 8, min: 42, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 8, min: 46, secs: 0)!,
                       end: currentDate.dateBySet(hour: 9, min: 28, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 9, min: 32, secs: 0)!,
                       end: currentDate.dateBySet(hour: 10, min: 32, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 10, min: 42, secs: 0)!,
                       end: currentDate.dateBySet(hour: 11, min: 24, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 11, min: 28, secs: 0)!,
                       end: currentDate.dateBySet(hour: 12, min: 10, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 12, min: 14, secs: 0)!,
                       end: currentDate.dateBySet(hour: 12, min: 56, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 13, min: 0, secs: 0)!,
                       end: currentDate.dateBySet(hour: 13, min: 38, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 13, min: 42, secs: 0)!,
                       end: currentDate.dateBySet(hour: 14, min: 24, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 14, min: 28, secs: 0)!,
                       end: currentDate.dateBySet(hour: 15, min: 10, secs: 0)!)
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
    
    if currentTime.isBeforeDate(period.start, granularity: .second) {
        timerString = "Starts in "
        difference = period.start - currentTime
    } else if currentTime.isBeforeDate(period.end, granularity: .second) {
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
    case 8: return "1:42PM - 2:24PM"
    case 9: return "2:28PM - 3:10PM"
    default: return "Error!"
    }
}

func getCurrentPeriod() -> Int {
    SwiftDate.defaultRegion = Region.local
    let currentTime = DateInRegion()
    print(currentTime)
    let period = ClassTime().period
    
    switch currentTime {
    case currentTime.dateAt(.startOfDay)..<period[0].end:
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

func getClassDataAt(period: Int, day: String) -> [[String: Any]] {
    //var period = period
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
             listClasses[4 - period] = meetingForWorship
            //                currentClass == 1 -> index = 3
            //                currentClass == 2 -> index = 2
            //                currentClass == 3 -> index = 1
            //                currentClass == 4 -> index = 0
        }
    }
    

    return listClasses
}
