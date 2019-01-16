//
//  CMH.swift
//  MFSMobile
//
//  Created by 戴元平 on 1/15/19.
//  Copyright © 2019 David. All rights reserved.
//

import Foundation

class CMH: School {
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
}
