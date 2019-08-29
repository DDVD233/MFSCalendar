//
//  MFSClasses.swift
//  This is the MFS school class.
//  Any school-specific functions/variables should go there.
//  Be sure to override all the functions in the parent class. 
//
//  Created by David Dai on 2/15/18.
//  Copyright © 2018 David. All rights reserved.
//

import Foundation

public class MFS: School {
    
    override init() {
        super.init()
        self.dayLetterList = "ABCDEF"
    }
    
    // MAINTAIN: This value must be updated every year.
//    override func getMarkingPeriodID(quarter: Int) -> Int {
//        switch quarter {
//        case 1:
//            return 6893
//        case 2:
//            return 6894
//        case 3:
//            return 6895
//        case 4:
//            return 6896
//        default:
//            return 0
//        }
//    }
    
    override func getClassDataAt(date: Date) -> [[String: Any]] {
        //var period = period
        listClasses = [[String: Any]]()
        let day = dayCheck(date: date)
        
        let path = FileList.classDate(date: day).filePath
        
        guard let allClasses = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
            return listClasses
        }
        
        listClasses = allClasses
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE"
        let weekDay = dateFormatter.string(from: date)
        //let lunch = ["className": "Lunch", "roomNumber": "DH/C", "teacher": "", "period": 11] as [String: Any]
        if listClasses.count >= 6 && weekDay == "Wed" {
            let meetingForWorship = ["className": "Meeting For Worship", "roomNumber": "Meeting House", "teacher": "", "period": 4, "startTime": 1042, "endTime": 1124] as [String: Any]
            listClasses[3] = meetingForWorship
        }
        
        
        
        return listClasses
    }
    
    override func getClassDataAt(day: String) -> [[String: Any]] {
        NSLog("Day: %@", day)
        let path = FileList.classDate(date: day).filePath
        
        if let data = NSArray(contentsOfFile: path) as? [[String: Any]] {
            self.listClasses = data
            return data
        }
        
        return [[String: Any]]()
    }
    
    func dayCheck(date: Date) -> String {
        var dayOfSchool: String? = nil
        let formatter = DateFormatter()
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = FileList.day.filePath
        let dayDict = NSDictionary(contentsOfFile: path)
        formatter.dateFormat = "yyyyMMdd"
        let checkDate = formatter.string(from: date)
        
        let noSchoolString = NSLocalizedString("No School", comment: "")
        dayOfSchool = dayDict?[checkDate] as? String ?? noSchoolString
        
        return dayOfSchool!
    }
}
