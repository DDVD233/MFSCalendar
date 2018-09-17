//
//  courseFill.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/5/23.
//  Copyright © 2017 David. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import SwiftMessages
import UICircularProgressRing
import LTMorphingLabel
import SwiftyJSON
import FirebasePerformance
import Alamofire
import SwiftDate
import CoreData

class courseFillController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBOutlet weak var progressView: UICircularProgressRing!
    @IBOutlet weak var topLabel: LTMorphingLabel!
    @IBOutlet weak var bottomLabel: LTMorphingLabel!

    let trace = Performance.startTrace(name: "course fill trace")
    let baseURL = Preferences().davidBaseURL

    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.font = UIFont.systemFont(ofSize: 40)
    }

    override func viewDidAppear(_ animated: Bool) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let date = formatter.string(from: Date())
        Preferences().refreshDate = date
        DispatchQueue.global().async {
<<<<<<< HEAD
            NetworkOperations().downloadLargeProfilePhoto()
        }
        
        DispatchQueue.global().async {
            if Preferences().isStudent {
                self.importCourseStudent()
            } else {
                self.importCourseTeacher()
            }
=======
            self.importCoursePrimary()
>>>>>>> master
        }
    }
    
    // Get the quarter data from David Server. Format: Array(Dict(Quarter: Int, BeginDate: Int, ReferenceNumber: Int))
    func setQuarter() {
<<<<<<< HEAD
        NetworkOperations().getQuarterSchedule()
        
        let quarterDataPath = URL(fileURLWithPath: userDocumentPath + "/QuarterSchedule.plist")
        guard let quarterData = NSArray(contentsOf: quarterDataPath) as? [[String: Any]] else {
            presentErrorMessage(presentMessage: "Quarter data not found", layout: .cardView)
            return
        }
        
        for quarter in quarterData {
            guard let beginDateInt = quarter["BeginDate"] as? Int else {
                return
            }
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyyMMdd"
            
            guard let beginDate = dateFormatter.date(from: String(beginDateInt)) else {
                return
            }
            
            if Date().isAfterDate(beginDate, granularity: .day) {
                let preferences = Preferences()
                preferences.currentQuarter = quarter["Quarter"] as! Int
                preferences.durationID = String(describing: quarter["ReferenceNumber"] as! Int)
            }
=======
        var thirdQuarterStartComponent = DateComponents()
        thirdQuarterStartComponent.year = 2018
        thirdQuarterStartComponent.month = 1
        thirdQuarterStartComponent.day = 20
        let thirdQuarterStart = DateInRegion(components: thirdQuarterStartComponent)!
        
        var fourthQuarterStartComponent = DateComponents()
        fourthQuarterStartComponent.year = 2018
        fourthQuarterStartComponent.month = 4
        fourthQuarterStartComponent.day = 1
        let fourthQuarterStart = DateInRegion(components: thirdQuarterStartComponent)!
        
        if DateInRegion().isBefore(date: thirdQuarterStart, granularity: .day) {
            Preferences().currentQuarter = 2
        } else if DateInRegion().isBefore(date: fourthQuarterStart, granularity: .day) {
            Preferences().currentQuarter = 3
        } else {
            Preferences().currentQuarter = 4
>>>>>>> master
        }
    }
    
    func importCoursePrimary() {
        NetworkOperations().refreshData()
        
        if Preferences().schoolCode == "CMH" {
            importCourseCMH()
        } else {
            if Preferences().isStudent {
                importCourseStudent()
            } else {
                importCourseTeacher()
            }
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            self.viewDismiss()
        })
    }
    
    func importCourseCMH() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        updateQuarterIfNeeded()
        
        guard self.newGetCourse() else {
            return
        }
        
        setProgressTo(value: 33)
        
        importCourseMySchool()
        setProgressTo(value: 66)
        
        ClassView().getProfilePhoto()
        versionCheck()
        setProgressTo(value: 100)
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.topLabel.text = "Success"
            self.bottomLabel.text = "Successfully updated"
        }
    }
    
    func importCourseTeacher() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        updateQuarterIfNeeded()
        
        guard self.newGetCourse() else {
            return
        }
        
        fillAdditionalInformarion()
        setProgressTo(value: 33)
        
        for alphabet in "ABCDEF" {
            clearData(day: String(alphabet))
        }
        guard createSchedule(fillLowPriority: 0) else {
            return
        }
        setProgressTo(value: 66)
        
        guard createSchedule(fillLowPriority: 1) else {
            return
        }
        for alphabet in "ABCDEF" {
            self.fillStudyHallAndLunch(letter: String(alphabet))
        }
        
        ClassView().getProfilePhoto()
        versionCheck()
        setProgressTo(value: 100)
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.topLabel.text = "Success"
            self.bottomLabel.text = "Successfully updated"
        }
    }
    
    func importCourseStudent() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        if !self.NCIsRunning() {
            self.importCourseTeacher()
            return
        }
        
        updateQuarterIfNeeded()
        
        let group = DispatchGroup()
        var schedule = [[String: Any]]()
        
        DispatchQueue.global().async(group: group, execute: {
            guard self.newGetCourse() else {
                return
            }
            
            self.setProgressTo(value: 33)
            
            ClassView().getProfilePhoto()
            self.versionCheck()
            
            self.setProgressTo(value: 66)
        })
        
        DispatchQueue.global().async(group: group, execute: {
            for alphabet in "ABCDEF" {
                self.clearData(day: String(alphabet))
            }
            
            guard let gotSchedule = self.getScheduleNC() else {
                return
            }
            
            schedule = gotSchedule
            
            //self.fillAdditionalInformarion()
        })
        
        group.wait()
        
        self.createScheduleNC(schedule: schedule)
        
        for alphabet in "ABCDEF" {
            self.fillStudyHallAndLunch(letter: String(alphabet))
        }

        setProgressTo(value: 100)
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
            self.topLabel.text = "Success"
            self.bottomLabel.text = "Successfully updated"
        }
    }
    
    func updateQuarterIfNeeded() {
        if Preferences().doUpdateQuarter {
            setQuarter()
        } else {
            Preferences().doUpdateQuarter = true
        }
    }
    
    func importCourseMySchool() {
        let mySchoolScheduleFill = MySchoolScheduleFill()
        let currentSchoolYear = DateInRegion().month < 8 ? DateInRegion().year - 1 : DateInRegion().year
        let startComponents: [Calendar.Component : Int] = [.year: currentSchoolYear, .month: 8, .day: 1]
        guard let startDate = DateInRegion(components: startComponents) else {
            fatalError("StartDate failed to create")
        }
        
        let endDate = startDate + 1.year
        let courses = mySchoolScheduleFill.getScheduleFromMySchool(startTime: startDate.absoluteDate, endTime: endDate.absoluteDate)
        mySchoolScheduleFill.storeMySchoolSchedule(scheduleData: courses)
    }
    
    func setProgressTo(value: CGFloat) {
        DispatchQueue.main.async {
            self.progressView.startProgress(to: value, duration: 1)
        }
    }
    
    func createScheduleData() {
        let letterDayListPath = URL(fileURLWithPath: userDocumentPath.appending("/Day.plist"))
        guard let letterDayList = NSDictionary(contentsOf: letterDayListPath) as? [String: String?] else {
            print("Letter day file has incorrect format")
            return
        }
        
        let scheduleData = [String: [String: Any]]()
        for (key, value) in letterDayList {
            let courseObject = NSEntityDescription.insertNewObject(forEntityName: "Course", into: managedContext!) as! CourseMO
            
            guard key.count == 8 else { continue }
            guard let letter = value else { continue }
            
            let fileName = "/Class" + letter + ".plist"
            let path = URL.init(fileURLWithPath: userDocumentPath.appending(fileName))
            guard let classInDay = NSArray(contentsOf: path) as? [[String: Any]] else {
                continue
            }
            
            let startIndex = key.startIndex
            let monthIndexBegin = key.index(startIndex, offsetBy: 4)
            let dayIndexBegin = key.index(startIndex, offsetBy: 6)
            let year = Int(key[..<monthIndexBegin])!
            let month = Int(key[monthIndexBegin..<dayIndexBegin])!
            let day = Int(key[dayIndexBegin...])!
            let components: [Calendar.Component:Int] = [.year: year, .month: month, .day: day]
            guard let date = DateInRegion(components: components) else { continue }
            
            for (index, course) in classInDay.enumerated() {
                let classTime = ClassTime(date: date)
                let period = classTime.period[index]
                
                let startTime = period.start
                courseObject.startTime = startTime.absoluteDate
                
                let endTime = period.end
                courseObject.endTime = endTime.absoluteDate
                
                courseObject.name = course["className"] as? String
                courseObject.room = course["roomNumber"] as? String
                courseObject.teacherName = course["teacherName"] as? String
            }
        }
        
        do {
            try managedContext?.save()
        } catch {
            presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
        }
    }
    
    func viewDismiss() {
        Preferences().courseInitialized = true
        self.trace?.stop()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        self.dismiss(animated: true)
    }
    
    func NCIsRunning() -> Bool {
        var isRunning = true
        let url = self.baseURL + "/NCIsRunning"
        let semaphore = DispatchSemaphore(value: 0)
        Alamofire.request(url).response { (result) in
            guard result.error == nil else {
                presentErrorMessage(presentMessage: result.error!.localizedDescription, layout: .statusLine)
                semaphore.signal()
                return
            }
            
            guard let statusCode = String(data: result.data!, encoding: .utf8) else {
                presentErrorMessage(presentMessage: "Failed to check if NetClassroom is running.", layout: .statusLine)
                semaphore.signal()
                return
            }
            
            if statusCode == "0" {
                isRunning = false
            } else {
                isRunning = true
            }
            
            semaphore.signal()
        }
        
        semaphore.wait()
        return isRunning
    }
    
    func getScheduleNC() -> [[String: Any]]? {
        let token = loginAuthentication().token
        
        let courseInfo = ["token": token]
        guard let json = try? JSONSerialization.data(withJSONObject: courseInfo, options: .prettyPrinted) else {
            return nil
        }
        let semaphore = DispatchSemaphore.init(value: 0)
        let urlString = "http://127.0.0.1:5000" + "/getScheduleNC"
        let url = URL(string: urlString)
        var request = URLRequest(url: url!)
        request.httpMethod = "POST"
        request.httpBody = json
        let session = URLSession.shared
        
        var schedule: [[String: Any]]? = nil
        
        let task = session.dataTask(with: request, completionHandler: { (data, response, error) in
            guard error == nil else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .cardView)
                
                semaphore.signal()
                return
            }
            
//            print(String.init(data: data!, encoding: .utf8))
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String: Any]] else {
                    presentErrorMessage(presentMessage: "JSON file has incorrect format.", layout: .cardView)
                    return
                }
                
                print(json)
                schedule = json
            } catch {
                print(String(data: data!, encoding: .utf8) as Any)
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
            }
            
            semaphore.signal()
        })
        
        task.resume()
        semaphore.wait()
        return schedule
    }
    
    func createScheduleNC(schedule: [[String: Any]]) {
        // classID: String = Class ID
        // className: Strinng = Class Name
        // quarter: String = Quarter ("1"/"2"/"3"/"4")
        for courses in schedule {
            var courses = courses
            print(courses)
            guard let meetTimeList = courses["meetTime"] as? [String],
                  let quarter = courses["quarter"] as? String,
                  let className = courses["className"] as? String,
                  let teacherName = courses["teacherName"] as? String
                  else {
                continue
            }
            
            guard Int(quarter) ?? 0 == Preferences().currentQuarter else {
                continue
            }
            
            let coursePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
            let path = coursePath.appending("/CourseList.plist")
            if let coursesList = NSArray(contentsOfFile: path)! as? Array<Dictionary<String, Any>> {
                if let courseIndex = coursesList.index(where: { ($0["className"] as? String ?? "").contains(className) &&
                                                                $0["teacherName"] as? String == teacherName
                }) {
                    courses["index"] = Int(courseIndex)
                }
            }
            
            for meetTime in meetTimeList {
                guard !meetTime.isEmpty else {
                    continue
                }
                
                let day = meetTime[0, 0]
                let period = Int(meetTime[1, 1])!
                
                guard period > 0 else {
                    continue
                }
                
                let fileName = "/Class" + day + ".plist"
                let path = userDocumentPath.appending(fileName)
                
                guard var classOfDay = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
                    continue
                }
                
                let classOfThePeriod = classOfDay[period - 1]
                
                if classOfThePeriod.count == 0 {
                    courses["period"] = period
                    classOfDay[period - 1] = courses
                    NSArray(array: classOfDay).write(toFile: path, atomically: true)
                }
            }
        }
    }

    func newGetCourse() -> Bool {
        var success = false
        let semaphore = DispatchSemaphore.init(value: 0)
        //create request.
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil

        let session = URLSession.init(configuration: config)

        let (_, _, userId) = loginAuthentication()

        guard let durationId = Preferences().durationID else {
            return false
        }

<<<<<<< HEAD
        let urlString = "https://mfriends.myschoolapp.com/api/datadirect/ParentStudentUserAcademicGroupsGet?userId=\(userId)&schoolYearLabel=2018+-+2019&memberLevel=3&persona=2&durationList=\(durationId)"
=======
        let urlString = Preferences().baseURL + "/api/datadirect/ParentStudentUserAcademicGroupsGet?userId=\(userId)&schoolYearLabel=2017+-+2018&memberLevel=3&persona=2&durationList=\(durationId)"
>>>>>>> master
        print(urlString)

        let url = URL(string: urlString)
        let request = URLRequest(url: url!)

        let downloadTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                guard var courseData = try! JSON(data: data!).arrayObject else {
                    print(String.init(data: data!, encoding: .utf8) as Any)
                    semaphore.signal()
                    return
                }
                
                print(courseData)

                for (index, item) in courseData.enumerated() {
                    guard var course = item as? Dictionary<String, Any?> else {
                        continue
                    }
                    print(course)
                    course["className"] = course["sectionidentifier"] as? String
                    course["teacherName"] = course["groupownername"] as? String
                    course["index"] = index
//                    If I do not delete nill value, it will not be able to write to plist.
                    for (key, value) in course {
                        if (value as? NSNull) == NSNull() {
                            course[key] = ""
                        }
                    }
                    courseData[index] = course
                }

                let coursePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                let path = coursePath.appending("/CourseList.plist")
                print(path)
                NSArray(array: courseData).write(to: URL.init(fileURLWithPath: path), atomically: true)
                success = true
            } else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
            }
            semaphore.signal()
        })
        //使用resume方法启动任务
        downloadTask.resume()
        semaphore.wait()
        return success
    }
    
    func fillAdditionalInformarion() {
        let coursePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = coursePath.appending("/CourseList.plist")
        guard let courseList = NSMutableArray(contentsOfFile: path) as? Array<NSMutableDictionary> else {
            return
        }

        let group = DispatchGroup()
        let queue = DispatchQueue.global()
        var filledCourse = [NSMutableDictionary]()

        for course in courseList {
            queue.async(group: group) {
                guard let courseName = course["className"] as? String else {
                    return
                }
                print(courseName)
                let teacherName = course["teacherName"] as? String ?? ""
                print(teacherName)
                // var urlString = "https://dwei.org/getAdditionalInformation/\(courseName)/\(teacherName ?? "None")"
                let urlString = self.baseURL + "/getAdditionalInformation"
                let courseInfo = ["courseName": courseName, "teacherName": teacherName]
                guard let json = try? JSONSerialization.data(withJSONObject: courseInfo, options: .prettyPrinted) else {
                    return
                }
                // urlString = urlString.replace(target: " ", withString: "+")
                let semaphore = DispatchSemaphore.init(value: 0)
                let url = URL(string: urlString)
                var request = URLRequest(url: url!)
                request.httpMethod = "POST"
                request.httpBody = json
                let session = URLSession.shared

                let downloadTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                    if error == nil {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! Array<NSDictionary>
                            print(json)

                            for infoToAdd in json {
                                print(infoToAdd)
                                let courseToAdd = course.mutableCopy() as! NSMutableDictionary
                                courseToAdd.addEntries(from: infoToAdd as! [String: Any])
                                filledCourse.append(courseToAdd)
                            }

                        } catch {
                            
                            print(String(data: data!, encoding: .utf8) as Any)
                            NSLog("Failed parsing the data")
                        }
                    } else {
                        presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
                    }
                    semaphore.signal()
                })
                //使用resume方法启动任务
                downloadTask.resume()
                semaphore.wait()
            }
        }

        group.wait()

        filledIndex(array: &filledCourse)
        NSArray(array: filledCourse).write(toFile: path, atomically: true)
    }

    func filledIndex(array: inout Array<NSMutableDictionary>) {
        for (index, item) in array.enumerated() {
            item["index"] = index
            array[index] = item
        }
    }

    func clearData(day: String) {
        let coursePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Class" + day + ".plist"
        let path = coursePath.appending(fileName)
        let blankArray = Array(repeating: [String: Any?](), count: 9)
        NSArray(array: blankArray).write(toFile: path, atomically: true)
    }

    func createSchedule(fillLowPriority: Int) -> Bool {
        var success = false
        let coursePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = coursePath.appending("/CourseList.plist")
        guard var coursesObject = NSArray(contentsOfFile: path)! as? Array<Dictionary<String, Any>> else {
            return false
        }
        
        var removeIndex = [Int]()

        let group = DispatchGroup()
        let queue = DispatchQueue.global()

        for (index, items) in coursesObject.enumerated() {
            var course = items
//            Rewrite!!!
            success = true

            guard let className = course["className"] as? String else {
                continue
            }
            
            guard !className.contains("Break") && !className.contains("Lunch") else {
                continue
            }

            queue.async(group: group) {
                let lowPriority = course["lowPriority"] as? Int ?? 0

                guard lowPriority == fillLowPriority else {
                    return
                }

                //When the block is not empty
                let semaphore = DispatchSemaphore.init(value: 0)
                guard var classId = course["id"] as? String else {
                    presentErrorMessage(presentMessage: "Course ID not found", layout: .statusLine)
                    return
                }
                
                classId = classId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let url = self.baseURL + "/searchbyid/" + classId
                
                let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { (data, response, error) in
                    guard error == nil else {
                        presentErrorMessage(presentMessage: error!.localizedDescription, layout: .cardView)
                        return
                    }
                    
                    do {
                        guard let meetTimeList = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Array<String> else {
                            semaphore.signal()
                            return
                        }
                        
                        print(meetTimeList)
                        
                        removeIndex += self.writeScheduleToFile(meetTimeList: meetTimeList, course: &course, index: index)
                        success = true
                    } catch {
                        presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                    }
                    
                    semaphore.signal()
                })
                
                task.resume()
                semaphore.wait()
            }
        }

        group.wait()


        if !removeIndex.isEmpty {
            coursesObject = coursesObject.enumerated().filter({ !removeIndex.contains($0.offset) }).map({ $0.element })
            NSArray(array: coursesObject).write(toFile: path, atomically: true)
        }

        return success
    }
    
    func writeScheduleToFile(meetTimeList: [String], course: inout [String: Any], index: Int) -> [Int] {
        var removeIndex = [Int]()
        let className = course["className"] as? String ?? ""
        
        //                            遍历所有的meet time， 格式为day + period
        for meetTime in meetTimeList {
            guard !meetTime.isEmpty else {
                continue
            }
            
            let day = meetTime[0, 0]
            var period = Int(meetTime[1, 1])!
            period = (period < 7) ? period : period + 1 // If before lunch, then period, otherwise period + 1.
            let fileName = "/Class" + day + ".plist"
            let path = userDocumentPath.appending(fileName)
            
            guard var classOfDay = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
                continue
            }
            
            let classOfThePeriod = classOfDay[period - 1]
            
            if classOfThePeriod.count == 0 {
                course["period"] = period
                classOfDay[period - 1] = course
                NSArray(array: classOfDay).write(toFile: path, atomically: true)
            } else if className.count >= 10 && className[0, 9] == "Study Hall" {
                //         It is possible that a study hall that the user doesn't take appear on the course list.
                removeIndex.append(index)
            }
        }
        
        return removeIndex
    }

//    Finish creating schedule
    func fillStudyHallAndLunch(letter: String) {
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Class" + letter + ".plist"
        let path = plistPath.appending(fileName)
        var listClasses = NSArray(contentsOfFile: path) as! [[String: Any]]
        
        let lunch = ["className": "Lunch", "period": 7, "roomNumber": "DH/C", "teacher": ""] as [String : Any]
        listClasses[6] = lunch
        
        if letter == "B" {
            let assembly = ["className": "Assembly", "period": 5, "roomNumber": "Auditorium", "teacher": ""] as [String : Any]
            listClasses[4] = assembly
        }
        
        let meetTimeListPath = Bundle.main.path(forResource: "ScheduleMFS", ofType: "plist")!
        let meetTimeList = NSArray(contentsOfFile: meetTimeListPath) as! [[String: String]]
        
        for periodNumber in 1...9 {
            if var classAtPeriod = listClasses.filter({ $0["period"] as? Int == periodNumber }).first {
                let periodTime = meetTimeList[periodNumber - 1]
                classAtPeriod["MyDayStartTime"] = periodTime["StartTime"]
                classAtPeriod["MyDayEndTime"] = periodTime["EndTime"]
                listClasses[periodNumber - 1] = classAtPeriod
            } else {
                let addData = ["className": "Free", "period": periodNumber] as [String : Any]
                listClasses[periodNumber - 1] = addData
            }
        }
        
        NSArray(array: listClasses).write(toFile: path, atomically: true)
    }

    func versionCheck() {
        let semaphore = DispatchSemaphore.init(value: 0)
        
        let url = URL(string: baseURL + "/dataversion")!
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard error ==  nil else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
                semaphore.signal()
                return
            }
            
            guard let version = String(data: data!, encoding: .utf8) else {
                semaphore.signal()
                return
            }
            
            let versionNumber = Int(version)!
            Preferences().version = versionNumber
            NSLog("Data refreshed to %#", version)
            
            semaphore.signal()
        })
        
//        provider.request(MyService.dataVersionCheck, completion: { result in
//            switch result {
//            case let .success(response):
//                guard let version = try? response.mapString() else {
//                    semaphore.signal()
//                    return
//                }
//                
//                guard let versionNumber = Int(version) else {
//                    semaphore.signal()
//                    return
//                }
//                
//                print("Version: ", versionNumber)
//                userDefaults?.set(versionNumber, forKey: "version")
//                NSLog("Data refreshed to %#", version)
//            case let .failure(error):
//                presentErrorMessage(presentMessage: error.localizedDescription, layout: .CardView)
//            }
//            
//            semaphore.signal()
//        })
        task.resume()
        semaphore.wait()
    }
}
