//
//  ProjectPublicFunctions.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/9/2.
//  Copyright © 2017 David. All rights reserved.
//

import Foundation
import SwiftDate
import CoreData

struct ClassTime {
    var currentDate: DateInRegion
    
    init() {
        SwiftDate.defaultRegion = Region.local
        self.currentDate = DateInRegion()
    }
    
    init(date: DateInRegion) {
        self.currentDate = date
    }
    
    var period: [Period] {
        return [Period(start: currentDate.dateBySet(hour: 8, min: 0, secs: 0)!,
                       end: currentDate.dateBySet(hour: 8, min: 42, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 8, min: 46, secs: 0)!,
                       end: currentDate.dateBySet(hour: 9, min: 28, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 9, min: 32, secs: 0)!,
                       end: currentDate.dateBySet(hour: 10, min: 32, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 10, min: 42, secs: 0)!,
                       end: currentDate.dateBySet(hour: 11, min: 24, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 11, min: 28, secs: 0)!,
                       end: currentDate.dateBySet(hour: 12, min: 10, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 12, min: 14, secs: 0)!,
                       end: currentDate.dateBySet(hour: 12, min: 56, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 13, min: 0, secs: 0)!,
                       end: currentDate.dateBySet(hour: 13, min: 38, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 13, min: 42, secs: 0)!,
                       end: currentDate.dateBySet(hour: 14, min: 24, secs: 0)!),
                Period(start: currentDate.dateBySet(hour: 14, min: 28, secs: 0)!,
                       end: currentDate.dateBySet(hour: 15, min: 10, secs: 0)!)
                ]
    }
}

struct Period {
    var start: DateInRegion
    var end: DateInRegion
    
    init(start: DateInRegion, end: DateInRegion) {
        self.start = start
        self.end = end
    }
}

func periodTimerString(course: CourseMO) -> String {
    assert(course.startTime != nil)
    assert(course.endTime != nil)
    var timerString: String = ""
    let currentTime = DateInRegion()
    let periodStartTime = DateInRegion(absoluteDate: course.startTime ?? Date())
    let periodEndTime = DateInRegion(absoluteDate: course.endTime ?? Date())
    
    print(currentTime)
    
    var difference: TimeInterval? = nil
    
<<<<<<< HEAD
    if currentTime.isBeforeDate(period.start, granularity: .second) {
        timerString = "Starts in "
        difference = (period.start - currentTime).timeInterval
    } else if currentTime.isBeforeDate(period.end, granularity: .second) {
        timerString = "Ends in "
        difference = (period.end - currentTime).timeInterval
    } else {
        timerString = "Ended "
        difference = (currentTime - period.end).timeInterval
=======
    if currentTime.isBefore(date: periodStartTime, granularity: .second) {
        timerString = "Starts in "
        difference =  periodStartTime - currentTime
    } else if currentTime.isBefore(date: periodEndTime, granularity: .second) {
        timerString = "Ends in "
        difference = periodEndTime - currentTime
    } else {
        timerString = "Ended "
        difference = currentTime - periodEndTime
>>>>>>> master
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

<<<<<<< HEAD
func getMeetTime(period: Int) -> String {
    switch period {
    case 1: return "8:00AM - 8:42AM"
    case 2: return "8:46AM - 9:28AM"
    case 3: return "9:32AM - 10:32AM"
    case 4: return "10:42AM - 11:24AM"
    case 5: return "11:28AM - 12:10AM"
    case 6: return "12:14PM - 12:56PM"
    case 7: return "1:00PM - 1:38PM"
    case 8: return "1:42PM - 2:23PM"
    case 9: return "2:24PM - 3:10PM"
    default: return "Error!"
    }
}

func getCurrentPeriod() -> Int {
    let currentTime = DateInRegion()
    print(currentTime)
    let period = ClassTime().period
    
    switch currentTime {
    case currentTime.dateAt(.startOfDay)..<period[0].end:
        return 1
    case period[0].end..<period[1].end:
        return 2
    case period[1].end..<period[2].end:
        return 3
    case period[2].end..<period[3].end:
        return 4
    case period[3].end..<period[4].end:
        return 5
    case period[4].end..<period[5].end:
        return 6
    case period[5].end..<period[6].end:
        return 7
    case period[6].end..<period[7].end:
        return 8
    case period[7].end..<period[8].end:
        return 9
    default:
        return 10
    }
}

func getClassDataAt(period: Int, day: String) -> [[String: Any]] {
    //var period = period
    var listClasses = [[String: Any]]()
=======
//func getMeetTime(period: Int) -> String {
//    switch period {
//    case 1: return "8:00AM - 8:42AM"
//    case 2: return "8:46AM - 9:28AM"
//    case 3: return "9:32AM - 10:32AM"
//    case 4: return "10:42AM - 11:24AM"
//    case 5: return "11:28AM - 12:10AM"
//    case 6: return "12:14PM - 12:56PM"
//    case 7: return "1:00PM - 1:38PM"
//    case 8: return "1:42PM - 2:23PM"
//    case 9: return "2:24PM - 3:10PM"
//    default: return "Error!"
//    }
//}
>>>>>>> master

//func getCurrentPeriod(classList: [CourseMO]) -> Int {
//    let currentTime = DateInRegion()
//
//}

func getMeetTimeInterval(classData: CourseMO) -> String? {
    var intervalString = ""
    guard let startTime = classData.startTime else {
        return intervalString
    }
    
    guard let endTime = classData.endTime else {
        return intervalString
    }
    
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a"
    
    intervalString = formatter.string(from: startTime) + " - " + formatter.string(from: endTime)
    
    return intervalString
}

func dayCheck(date: Date) -> String {
    var dayOfSchool: String? = nil
    let formatter = DateFormatter()
    let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
    let path = plistPath.appending("/Day.plist")
    guard let dayDict = NSDictionary(contentsOfFile: path) as? [String: String] else {
        return "No School"
    }
    formatter.dateFormat = "yyyyMMdd"
    let checkDate = formatter.string(from: date)
    
    dayOfSchool = dayDict[checkDate] ?? "No School"
    return dayOfSchool!
}

class ManagedContext {
    let coreDataFileName = "MFSCalender"
    lazy var applicationDocumentsDirectory: NSURL = {
        let urls = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        return urls[urls.count-1] as NSURL
    }()
    lazy var managedObjectModel: NSManagedObjectModel = {
        // 1
        let modelURL = Bundle.main.url(forResource: coreDataFileName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.appendingPathComponent("\(coreDataFileName).sqlite")
        do {
            // If your looking for any kind of migration then here is the time to pass it to the options
            try coordinator.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: nil)
        } catch let  error as NSError {
            print("Ops there was an error \(error.localizedDescription)")
            abort()
        }
        return coordinator
    }()
    lazy var managedObjectContext: NSManagedObjectContext = {
        //    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the
        //    application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to
        //    fail.
        let coordinator = self.persistentStoreCoordinator
        var context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        context.persistentStoreCoordinator = coordinator
        return context
    }()
}

func getClassDataAt(date: Date) -> [CourseMO] {
    let managedContext = ManagedContext().managedObjectContext
    let classRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Course")
    let startDate = date
    let endDate = date.atTime(hour: 23, minute: 59, second: 59)!
    classRequest.predicate = NSPredicate(format: "(startTime >= %@) AND (endTime <= %@)", argumentArray: [startDate, endDate])
    var listClasses = [CourseMO]()
    
<<<<<<< HEAD
=======
    do {
        let meetingForWorship = ["className": "Meeting For Worship", "roomNumber": "Meeting House", "teacher": "", "period": 4] as [String: Any]
        let fetchedClasses = try managedContext.fetch(classRequest) as! [CourseMO]
        listClasses = fetchedClasses.sorted(by: { $0.startTime ?? Date() < $1.endTime ?? Date() })
//        let period = getCurrentPeriod(classList: fetchedClasses)
    } catch {
        fatalError("Failed to fetch classes: \(error)")
    }
>>>>>>> master

    //let lunch = ["className": "Lunch", "roomNumber": "DH/C", "teacher": "", "period": 11] as [String: Any]
    
    return listClasses
}
