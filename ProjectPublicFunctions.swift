//
//  ProjectPublicFunctions.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/9/2.
//  Copyright © 2017年 David. All rights reserved.
//

import Foundation

func getCurrentPeriod(time: Int) -> Int {
    let Period1Start = 800
    let Period2Start = 847
    let Period3Start = 934
    let Period4Start = 1044
    let Period5Start = 1131
    let Period6Start = 1214
    let LunchStart = 1300
    let Period7Start = 1340
    let Period8Start = 1427
    let Period8End = 1510
    var currentClass: Int? = nil
    
    switch time {
    case 0..<Period1Start:
        NSLog("Period 0")
        currentClass = 1
    case Period1Start..<Period2Start:
        NSLog("Period 1")
        currentClass = 1
    case Period2Start..<Period3Start:
        NSLog("Period 2")
        currentClass = 2
    case Period3Start..<Period4Start:
        NSLog("Period 3")
        currentClass = 3
    case Period4Start..<Period5Start:
        NSLog("Period 4")
        currentClass = 4
    case Period5Start..<Period6Start:
        NSLog("Period 5")
        currentClass = 5
    case Period6Start..<LunchStart:
        NSLog("Period 6")
        currentClass = 6
    case LunchStart..<Period7Start:
        NSLog("Lunch")
        currentClass = 11
    case Period7Start..<Period8Start:
        NSLog("Period 7")
        currentClass = 7
    case Period8Start..<Period8End:
        NSLog("Period 8")
        currentClass = 8
    case Period8End..<3000:
        NSLog("After School.")
        currentClass = 9
    default:
        NSLog("???")
        currentClass = -1
    }
    
    return currentClass!
}

func getClassDataAt(period: Int, day: String) -> [[String: Any]] {
    var listClasses = [[String: Any]]()

    let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
    let fileName = "/Class" + day + ".plist"
    let path = plistPath.appending(fileName)

    guard let allClasses = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
        return listClasses
    }

    let lunch = ["className": "Lunch", "roomNumber": "DH/C", "teacher": "", "period": 11] as [String: Any]
    
    switch period {
    case 1...8:
        listClasses = Array(allClasses[(period - 1)...7])
        
        if listClasses.count >= 2 { //Before lunch
            listClasses.insert(lunch, at: 6 - period)
        }
    case 11:
        // At lunch
        
        listClasses = Array(allClasses[6...7])
        
        listClasses.insert(lunch, at: 0)
    default:
        listClasses = []
    }

    return listClasses
}
