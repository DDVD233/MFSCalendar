//
//  courseFill.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/5/23.
//  Copyright © 2017年 David. All rights reserved.
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

class courseFillController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBOutlet weak var progressView: UICircularProgressRingView!
    @IBOutlet weak var topLabel: LTMorphingLabel!
    @IBOutlet weak var bottomLabel: LTMorphingLabel!

    let trace = Performance.startTrace(name: "course fill trace")
    let baseURL = "https://dwei.org"

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
            self.importCourse()
        }
    }
    
    func setQuarter() {
        var thirdQuarterStartComponent = DateComponents()
        thirdQuarterStartComponent.year = 2018
        thirdQuarterStartComponent.month = 1
        thirdQuarterStartComponent.day = 20
        
        let thirdQuarterStart = DateInRegion(components: thirdQuarterStartComponent)!
        if DateInRegion().isBefore(date: thirdQuarterStart, granularity: .day) {
            Preferences().currentQuarter = 2
        } else {
            Preferences().currentQuarter = 3
        }
    }
    
    func importCourse() {
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        if Preferences().doUpdateQuarter {
            setQuarter()
        } else {
            Preferences().doUpdateQuarter = true
        }
        
        let group = DispatchGroup()
        var schedule = [[String: Any]]()
        
        DispatchQueue.global().async(group: group, execute: {
            guard self.newGetCourse() else {
                DispatchQueue.main.async {
                    self.viewDismiss()
                }
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
                DispatchQueue.main.async {
                    self.viewDismiss()
                }
                return
            }
            
            schedule = gotSchedule
            
            //self.fillAdditionalInformarion()
        })
        
        group.wait()
        
        self.createScheduleNC(schedule: schedule)
        
//        guard createSchedule(fillLowPriority: 0) else {
//            viewDismiss()
//            return
//        }
//        setProgressTo(value: 66)
//
//        guard createSchedule(fillLowPriority: 1) else {
//            return
//        }
        
        for alphabet in "ABCDEF" {
            self.fillStudyHallAndLunch(letter: String(alphabet))
        }

        setProgressTo(value: 100)
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
            self.topLabel.text = "Success"
            self.bottomLabel.text = "Successfully updated"
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(2), execute: {
            self.viewDismiss()
        })
    }
    
    func setProgressTo(value: CGFloat) {
        DispatchQueue.main.async {
            self.progressView.setProgress(value: value, animationDuration: 1)
        }
    }
    
    func viewDismiss() {
        Preferences().courseInitialized = true
        self.trace?.stop()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
        self.dismiss(animated: true)
    }
    
    func getScheduleNC() -> [[String: Any]]? {
        let token = loginAuthentication().token
        
        let courseInfo = ["token": token]
        guard let json = try? JSONSerialization.data(withJSONObject: courseInfo, options: .prettyPrinted) else {
            return nil
        }
        let semaphore = DispatchSemaphore.init(value: 0)
        let urlString = self.baseURL + "/getScheduleNC"
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
            
            do {
                guard let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String: Any]] else {
                    presentErrorMessage(presentMessage: "JSON file has incorrect format.", layout: .cardView)
                    return
                }
                
                print(json)
                schedule = json
            } catch {
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

        guard let durationId = NetworkOperations().getDurationId(for: Preferences().currentQuarter) else {
            return false
        }

        let urlString = "https://mfriends.myschoolapp.com/api/datadirect/ParentStudentUserAcademicGroupsGet?userId=\(userId)&schoolYearLabel=2017+-+2018&memberLevel=3&persona=2&durationList=\(durationId)"
        print(urlString)

        let url = URL(string: urlString)
        let request = URLRequest(url: url!)

        let downloadTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                guard var courseData = try! JSON(data: data!).arrayObject else {
                    semaphore.signal()
                    return
                }
                
                print(courseData)

                for (index, item) in courseData.enumerated() {
                    var course = (item as! NSDictionary).mutableCopy() as! Dictionary<String, Any>
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

                NSArray(array: courseData).write(toFile: path, atomically: true)
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
            let period = Int(meetTime[1, 1])!
            let fileName = "/Class" + day + ".plist"
            let path = userDocumentPath.appending(fileName)
            
            guard var classOfDay = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
                continue
            }
            
            let classOfThePeriod = classOfDay[period - 1]
            
            if classOfThePeriod.count == 0 {
                course["period"] = (period <= 7) ? period : period + 1 // If before lunch, then period, else period + 1.
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
        
        for periodNumber in 1...8 {
            if listClasses.filter({ $0["period"] as? Int == periodNumber }).count == 0 {
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
