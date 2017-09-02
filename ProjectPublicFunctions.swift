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
