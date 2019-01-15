//
//  SchoolProtocol.swift
//  MFSMobile
//
//  Created by David on 1/15/19.
//  Copyright © 2019 David. All rights reserved.
//

import Foundation
import SwiftDate

public class School {
    var listClasses = [[String: Any]]()
    func getClassDataAt(date: Date) -> [[String: Any]] {
        return listClasses
    }
    
    func classesOnADayAfter(date time: Date) -> [[String: Any]] {
        let classData = getClassDataAt(date: time)
        
        if classData.isEmpty {
            return classData
        }
        
        let sortedClassData = classData.sorted { (a, b) -> Bool in
            return (a["startTime"] as? Int ?? 0) < (b["startTime"] as? Int ?? 0)
        }
        
        print(sortedClassData)
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
        let currentTime = DateInRegion()
        print(currentTime)
        
        let startTimeInt = period["startTime"] as? Int ?? 0
        let startTime = DateInRegion().dateBySet([Calendar.Component.hour : Int(startTimeInt/100),
                                                  Calendar.Component.minute: Int(startTimeInt%100),
                                                  Calendar.Component.second: 0])!
        
        let endTimeInt = period["endTime"] as? Int ?? 0
        let endTime = DateInRegion().dateBySet([Calendar.Component.hour : Int(endTimeInt/100),
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
        guard let periodObject = getClassDataAt(date: date)[safe: period] else { return "" }
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
            amString = "AM"
        } else {
            amString = "PM"
        }
        
        let minute = Int(time%100)
        var minuteString = String(minute)
        if minute == 0 {
            minuteString = "00"
        }
        let timeString = String(hour) + ":" + minuteString + amString
        return timeString
    }
}

extension Collection {
    
    /// Returns the element at the specified index if it is within bounds, otherwise nil.
    subscript (safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
