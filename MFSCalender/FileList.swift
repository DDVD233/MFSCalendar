//
//  FileList.swift
//  MFSMobile
//
//  Created by 戴元平 on 5/17/19.
//  Copyright © 2019 David. All rights reserved.
//

import Foundation

enum FileList {
    case day
    case classDate(date: String)
    case courseList
    case events
    case topicsLeadSectionID(leadSectionID: String)
    case quarterSchedule // Format: Array(Dict(OfferingType: Int, DurationId: Int, DurationDescription: String, CurrentInd: Int))
}

extension FileList {
    var fileName: String {
        switch self {
        case .classDate(let date):
            return "Class" + date + ".plist"
        case .day:
            return "Day.plist"
        case .courseList:
            return "CourseList.plist"
        case .events:
            return "Events.plist"
        case .topicsLeadSectionID(let leadSectionID):
            return "Topics" + leadSectionID + ".plist"
        case .quarterSchedule:
            return "QuarterSchedule.plist"
        }
    }
    
    var filePath: String {
        return userDocumentPath + "/" + fileName
    }
    
    var arrayList: [Any] {
        return NSArray(contentsOfFile: filePath) as? [Any] ?? [Any]()
    }
}
