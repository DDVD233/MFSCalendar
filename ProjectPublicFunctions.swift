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
        self.currentDate = DateInRegion()
    }
    
    init(date: DateInRegion) {
        self.currentDate = date
    }
    
    var period: [Period] {
        return [Period(start: currentDate.atTime(hour: 8, minute: 0, second: 0)!,
                       end: currentDate.atTime(hour: 8, minute: 42, second: 0)!),
                Period(start: currentDate.atTime(hour: 8, minute: 46, second: 0)!,
                       end: currentDate.atTime(hour: 9, minute: 28, second: 0)!),
                Period(start: currentDate.atTime(hour: 9, minute: 32, second: 0)!,
                       end: currentDate.atTime(hour: 10, minute: 32, second: 0)!),
                Period(start: currentDate.atTime(hour: 10, minute: 42, second: 0)!,
                       end: currentDate.atTime(hour: 11, minute: 24, second: 0)!),
                Period(start: currentDate.atTime(hour: 11, minute: 28, second: 0)!,
                       end: currentDate.atTime(hour: 12, minute: 10, second: 0)!),
                Period(start: currentDate.atTime(hour: 12, minute: 14, second: 0)!,
                       end: currentDate.atTime(hour: 12, minute: 56, second: 0)!),
                Period(start: currentDate.atTime(hour: 13, minute: 0, second: 0)!,
                       end: currentDate.atTime(hour: 13, minute: 38, second: 0)!),
                Period(start: currentDate.atTime(hour: 13, minute: 42, second: 0)!,
                       end: currentDate.atTime(hour: 14, minute: 24, second: 0)!),
                Period(start: currentDate.atTime(hour: 14, minute: 28, second: 0)!,
                       end: currentDate.atTime(hour: 15, minute: 10, second: 0)!)
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
    
    if currentTime.isBefore(date: periodStartTime, granularity: .second) {
        timerString = "Starts in "
        difference =  periodStartTime - currentTime
    } else if currentTime.isBefore(date: periodEndTime, granularity: .second) {
        timerString = "Ends in "
        difference = periodEndTime - currentTime
    } else {
        timerString = "Ended "
        difference = currentTime - periodEndTime
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
    
    do {
        let meetingForWorship = ["className": "Meeting For Worship", "roomNumber": "Meeting House", "teacher": "", "period": 4] as [String: Any]
        let fetchedClasses = try managedContext.fetch(classRequest) as! [CourseMO]
        listClasses = fetchedClasses.sorted(by: { $0.startTime ?? Date() < $1.endTime ?? Date() })
//        let period = getCurrentPeriod(classList: fetchedClasses)
    } catch {
        fatalError("Failed to fetch classes: \(error)")
    }

    //let lunch = ["className": "Lunch", "roomNumber": "DH/C", "teacher": "", "period": 11] as [String: Any]
    
    return listClasses
}
