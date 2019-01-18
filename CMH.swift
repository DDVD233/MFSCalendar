//
//  CMH.swift
//  MFSMobile
//
//  Created by 戴元平 on 1/15/19.
//  Copyright © 2019 David. All rights reserved.
//

import Foundation

class CMH: School {
    
    override init() {
        super.init()
        self.dayLetterList = "AB"
    }
    
    override func getClassDataAt(date: Date) -> [[String: Any]] {
        //var period = period
        listClasses = [[String: Any]]()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let dateString = formatter.string(from: date)
        let fileName = "/Class" + dateString + ".plist"
        let path = userDocumentPath.appending(fileName)
        
        guard let allClasses = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
            return listClasses
        }
        
        listClasses = allClasses
        
        return listClasses
    }
    
    override func getClassDataAt(day: String) -> [[String: Any]] {
        let dayDictPath = userDocumentPath.appending("/Day.plist")
        guard let dayDict = NSDictionary(contentsOfFile: dayDictPath) as? [String: String] else { return [[String: Any]]() }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let today = formatter.string(from: Date())
        
        guard let date = dayDict.filter({ $0.value == day &&
            (Int($0.key) ?? 0 ) > (Int(today) ?? 0) }).first?.key else { return [[String: Any]]() }
        let schedulePath = userDocumentPath.appending("/Class" + date + ".plist")
        return NSArray(contentsOfFile: schedulePath) as? [[String: Any]] ?? [[String: Any]]()
    }
}
