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
    case supportedSchoolList
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
        case .supportedSchoolList:
            return "SupportedSchoolList.plist"
        }
    }
    
    var filePath: String {
        switch self {
        case .supportedSchoolList:
            var path = Bundle.main.bundlePath + "/Contents/Resources/" + fileName
            #if !targetEnvironment(macCatalyst)
                path = Bundle.main.bundlePath + "/" + fileName
            #endif
            print(path)
            return path
        default:
            return userDocumentPath + "/" + fileName
        }
    }
    
    var arrayList: [Any] {
        return NSArray(contentsOfFile: filePath) as? [Any] ?? [Any]()
    }
}
