//
//  SchoolProtocol.swift
//  MFSMobile
//
//  Created by David on 1/15/19.
//  Copyright © 2019 David. All rights reserved.
//

import Foundation
import SwiftDate
/** Class*.plist Structure
 *  classID     String
 *  className   String
 *  startTime   Int               Format: HHmm
 *  endTime     Int               Format: HHmm
 *  index       Int               Index of this class in course list
 *  period      Int               Period # in the day
 *  quarter     String            Or semester
 *  meetTime    [String: Any]
 *  roomNumber  String
 *  teacherName String
 **/
public class School {
    var listClasses = [[String: Any]]()
    var dayLetterList: String
    
    init() {
        dayLetterList = ""
    }
    func getClassDataAt(date: Date) -> [[String: Any]] {
        return listClasses
    }
    
    func getClassDataAt(day: String) -> [[String: Any]] {
        return listClasses
    }
    
//    func getMarkingPeriodID(quarter: Int) -> Int {
//        assert(false, "This method must be overriden!")
//        return 0
//    }
    
    func getDurationNumber(quarter: Int) -> Int {
        let quarterDataPath = FileList.quarterSchedule.filePath
        guard let quarterData = NSArray(contentsOfFile: quarterDataPath) as? [[String: Any]] else {
            return 0
        }
        
        guard quarterData.count >= quarter else {
            return 0
        }
        
        return quarterData[quarter - 1]["DurationId"] as? Int ?? 0
    }
    
    func getSchoolYear() -> Int {
        let year = Date().year
        let month = Date().month
        return (month > 6) ? year : year-1
    }
    
    func classesOnADayAfter(date time: Date) -> [[String: Any]] {
        let classData = getClassDataAt(date: time)
        
        if classData.isEmpty {
            return classData
        }
        
        let sortedClassData = classData.sorted { (a, b) -> Bool in
            return (a["startTime"] as? Int ?? 0) < (b["startTime"] as? Int ?? 0)
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HHmm"
        let currentTime = Int(dateFormatter.string(from: time)) ?? 0
        
        let filteredData = sortedClassData.filter { (a) -> Bool in
            return (a["endTime"] as? Int ?? 0) > currentTime
        }
        
        return filteredData
    }
    
    func periodTimerString(time: Date, index: Int) -> String {
        var timerString: String = ""
        guard let period = classesOnADayAfter(date: time)[safe: index] else { return "" }
        SwiftDate.defaultRegion = Region.local
        let currentTime = DateInRegion(time, region: Region.local)
        print(currentTime)
        
        let startTimeInt = period["startTime"] as? Int ?? 0
        let startTime = currentTime.dateBySet([Calendar.Component.hour : Int(startTimeInt/100),
                                                  Calendar.Component.minute: Int(startTimeInt%100),
                                                  Calendar.Component.second: 0])!
        
        let endTimeInt = period["endTime"] as? Int ?? 0
        let endTime = currentTime.dateBySet([Calendar.Component.hour : Int(endTimeInt/100),
                                                  Calendar.Component.minute: Int(endTimeInt%100),
                                                  Calendar.Component.second: 0])!
        
        var difference: TimeInterval? = nil
        
        if currentTime.isBeforeDate(startTime, granularity: .second) {
            timerString = "Starts in "
            difference = currentTime - startTime
        } else if currentTime.isBeforeDate(endTime, granularity: .second) {
            timerString = "Ends in "
            difference = currentTime - endTime
        } else {
            timerString = "Ended "
            difference = endTime - currentTime
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
    
    func meetTimeForPeriod(period: Int, date: Date) -> String {
        guard let periodObject = getClassDataAt(date: date)[safe: period - 1] else { return "" }
        let startTime = timeToAMFormat(time: periodObject["startTime"] as? Int ?? 0)
        let endTime = timeToAMFormat(time: periodObject["endTime"] as? Int ?? 0)
        return startTime + " - " + endTime
    }
    
    func meetTimeForPeriod(periodObject: [String: Any]) -> String {
        let startTime = timeToAMFormat(time: periodObject["startTime"] as? Int ?? 0)
        let endTime = timeToAMFormat(time: periodObject["endTime"] as? Int ?? 0)
        return startTime + " - " + endTime
    }
    
    func timeToAMFormat(time: Int) -> String {
        var hour = Int(time/100)
        var amString = ""
        if hour > 12 {
            hour -= 12
            amString = "PM"
        } else {
            amString = "AM"
        }
        
        let minute = Int(time%100)
        var minuteString = String(minute)
        if minute < 10 {
            minuteString = "0" + String(minute)
        }
        let timeString = String(hour) + ":" + minuteString + amString
        return timeString
    }
    
    func checkDate(checkDate: Date) -> String {
        let formatter = DateFormatter()
        let path = FileList.day.filePath
        guard let dayDict = NSDictionary(contentsOfFile: path) as? [String: String] else {
            return ""
        }
        formatter.dateFormat = "yyyyMMdd"
        let checkDateString = formatter.string(from: checkDate)
        let day = dayDict[checkDateString] ?? "No School"
        
        return day
    }
}

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
