//
//  MFSClasses.swift
//  MFSMobile
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
    
    override func getClassDataAt(date: Date) -> [[String: Any]] {
        //var period = period
        listClasses = [[String: Any]]()
        let day = dayCheck(date: date)
        
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Class" + day + ".plist"
        let path = plistPath.appending(fileName)
        
        guard let allClasses = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
            return listClasses
        }
        
        listClasses = allClasses
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EE"
        let weekDay = dateFormatter.string(from: date)
        //let lunch = ["className": "Lunch", "roomNumber": "DH/C", "teacher": "", "period": 11] as [String: Any]
        if listClasses.count >= 6 && weekDay == "Wed" {
            let meetingForWorship = ["className": "Meeting For Worship", "roomNumber": "Meeting House", "teacher": "", "period": 4] as [String: Any]
            listClasses[3] = meetingForWorship
        }
        
        
        
        return listClasses
    }
    
    override func getClassDataAt(day: String) -> [[String: Any]] {
        NSLog("Day: %@", day)
        let fileName = "/Class" + day + ".plist"
        let path = userDocumentPath.appending(fileName)
        
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
        let path = plistPath.appending("/Day.plist")
        let dayDict = NSDictionary(contentsOfFile: path)
        formatter.dateFormat = "yyyyMMdd"
        let checkDate = formatter.string(from: date)
        
        dayOfSchool = dayDict?[checkDate] as? String ?? "No School"
        
        return dayOfSchool!
    }
}
