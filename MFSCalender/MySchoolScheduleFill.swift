//
//  MyMFSScheduleFill.swift
//  MFSMobile
//
//  Created by David on 2/20/18.
//  Copyright © 2018 David. All rights reserved.
//

import Foundation
import SwiftDate

class MySchoolScheduleFill {
    func getScheduleFromMySchool(startTime: Date, endTime: Date) -> [[String: Any]] {
        let semaphore = DispatchSemaphore.init(value: 0)
        let userID = Preferences().userID ?? "0"
        let startTimeStamp = Int(startTime.timeIntervalSince1970)
        let endTimeStamp = Int(endTime.timeIntervalSince1970)
        var dictToReturn = [[String: Any]]()
        
        provider.request(MyService.mySchoolGetSchedule(startTimeStamp: String(startTimeStamp), endTimeStamp: String(endTimeStamp), userID: userID), callbackQueue: DispatchQueue.global()) { (result) in
            switch result {
            case let .success(response):
                do {
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? [[String: Any]] else {
                        presentErrorMessage(presentMessage: "JSON file has incorrect format.", layout: .statusLine)
                        return
                    }
                    
                    dictToReturn = json
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                }
            case let .failure(error):
                print(error.localizedDescription)
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
        return dictToReturn
    }
    
    func storeMySchoolSchedule(scheduleData: [[String: Any]]) {
        for course in scheduleData {
            var course = course
            let keysToRemove = course.keys.filter {
                guard let value = course[$0] else { return false }
                return (value as? NSNull) == NSNull()
            }
            
            for key in keysToRemove {
                course.removeValue(forKey: key)
            }
            
            if (course["allDay"] as? Bool ?? true) {
                writeDayDataToFile(course: course)
            }
        }
    }
    
    func writeDayDataToFile(course: [String: Any]) {
        guard let startTime = course["start"] as? String else {
            print("writeDayDataToFile: StartTimeNotFound")
            return
        }
        
        guard let date = DateInRegion(string: startTime, format: .custom("M/d/yyyy h:mm a")) else {
            presentErrorMessage(presentMessage: "writeDayDataToFile: Date cannot be converted", layout: .statusLine)
            return
        }
        
        guard let dayDescription = course["title"] as? String else {
            print("writeDayDataToFile: Title not found")
            return
        }
        
        let dateString = date.string(format: .custom("yyyyMMdd"))
        let abbreviation = abbreviateTitle(title: dayDescription)
        
        let dayDictPath = userDocumentPath.appending("/Day.plist")
        var dayDict = NSDictionary(contentsOfFile: dayDictPath) as? [String: String] ?? [String: String]()
        
        dayDict[dateString] = abbreviation
        NSDictionary(dictionary: dayDict).write(toFile: dateString, atomically: true)
    }
    
    func abbreviateTitle(title: String) -> String {
        var abbreviation = ""
        let components = title.components(separatedBy: [" ", "-"])
        if components.contains("Late") {
            abbreviation = "Late"
        } else if components.contains("Mass") {
            abbreviation = "Mass"
        }
        
        if let letter = components.filter({ $0.count == 1 }).first {
            abbreviation += letter
        }
        
        return abbreviation
    }
}
