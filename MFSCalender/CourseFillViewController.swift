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

class courseFillController: UIViewController {

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

    @IBOutlet weak var progressView: UICircularProgressRingView!
    @IBOutlet weak var topLabel: LTMorphingLabel!
    @IBOutlet weak var bottomLabel: LTMorphingLabel!

    let trace = Performance.startTrace(name: "course fill trace")

    override func viewDidLoad() {
        super.viewDidLoad()
        progressView.font = UIFont.systemFont(ofSize: 40)
    }

    override func viewDidAppear(_ animated: Bool) {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let date = formatter.string(from: Date())
        userDefaults?.set(date, forKey: "refreshDate")
        if importCourses() {
            NSLog("All Done!")
        }
    }

    func importCourses() -> Bool {
        progressView.setProgress(value: 2, animationDuration: 0.1)
        if self.newGetCourse() {
            fillAdditionalInformarion()
            fillSchedule()
        } else {
            self.dismiss(animated: true)
            userDefaults?.set(true, forKey: "courseInitialized")
        }
        return true
    }

    func fillSchedule() {
        progressView.setProgress(value: 33, animationDuration: 1) {
            self.clearData(day: "A")
            self.clearData(day: "B")
            self.clearData(day: "C")
            self.clearData(day: "D")
            self.clearData(day: "E")
            self.clearData(day: "F")
            if self.createSchedule(fillLowPriority: 0) {

                self.progressView.setProgress(value: 66, animationDuration: 1) {
                    if self.createSchedule(fillLowPriority: 1) {
                        self.getProfilePhoto()
                        self.versionCheck()
                        self.progressView.setProgress(value: 100, animationDuration: 1) {

                            self.topLabel.text = "Success"
                            self.bottomLabel.text = "Successfully updated"

                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
                                self.dismiss(animated: true, completion: nil)
                                self.trace?.stop()
                            })
                        }
                        NSLog("Success Filling schedules")
                        userDefaults?.set(true, forKey: "courseInitialized")
                    } else {
                        self.dismiss(animated: true)
                        self.trace?.stop()
                    }
                }
            } else {
                userDefaults?.set(true, forKey: "courseInitialized")
                self.dismiss(animated: true)
                self.trace?.stop()
            }
        }
    }

    func getProfilePhoto() {
        let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let coursePath = path.appending("/CourseList.plist")

        guard let courseList = NSArray(contentsOfFile: coursePath) as? Array<Dictionary<String, Any>> else {
            return
        }
        let group = DispatchGroup()
        let queue = DispatchQueue.global()

        for items in courseList {
            queue.async(group: group) {
                guard let sectionIdInt = items["sectionid"] as? Int else {
                    return
                }
                
                guard let photoURLPath = items["mostrecentgroupphoto"] as? String else {
                    return
                }
                
                guard loginAuthentication().success else {
                    return
                }
                
                guard !photoURLPath.isEmpty else {
                    NSLog("\(items["coursedescription"] as? String ?? "") has no photo.")
                    return
                }

                let sectionId = String(sectionIdInt)

                let photoLink = "https://bbk12e1-cdn.myschoolcdn.com/736/photo/" + photoURLPath

                let url = URL(string: photoLink)

                let downloadSemaphore = DispatchSemaphore.init(value: 0)

                let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                    let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                    let photoPath = path.appending("/\(sectionId)_profile.png")

                    let fileURL = URL(fileURLWithPath: photoPath)
                    print(fileURL)

                    downloadSemaphore.signal()

                    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                }
                
                
                Alamofire.download(url!, to: destination).resume()
                downloadSemaphore.wait()
            }
        }

        group.wait()
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

        guard let durationId = NetworkOperations().getDurationId() else {
            return false
        }

        let urlString = "https://mfriends.myschoolapp.com/api/datadirect/ParentStudentUserAcademicGroupsGet?userId=\(userId)&schoolYearLabel=2017+-+2018&memberLevel=3&persona=2&durationList=\(durationId)"

        let url = URL(string: urlString)
        let request = URLRequest(url: url!)

        let downloadTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                guard var courseData = JSON(data: data!).arrayObject else {
                    semaphore.signal()
                    return
                }

                for (index, item) in courseData.enumerated() {
                    var course = (item as! NSDictionary).mutableCopy() as! Dictionary<String, Any>
                    print(course)
                    course["className"] = course["sectionidentifier"] as? String
                    course["teacherName"] = course["groupownername"] as? String
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
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .StatusLine)
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
                let teacherName = course["teacherName"] as? String
                print(teacherName ?? "")
                var urlString = "https://dwei.org/getAdditionalInformation/\(courseName)/\(teacherName ?? "None")"
                urlString = urlString.replace(target: " ", withString: "+")
                let semaphore = DispatchSemaphore.init(value: 0)
                let url = URL(string: urlString)
                let request = URLRequest(url: url!)
                let session = URLSession.shared

                let downloadTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                    if error == nil {
                        do {
                            let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! Array<NSDictionary>

                            for infoToAdd in json {
                                print(infoToAdd)
                                let courseToAdd = course.mutableCopy() as! NSMutableDictionary
                                courseToAdd.addEntries(from: infoToAdd as! [String: Any])
                                filledCourse.append(courseToAdd)
                            }

                        } catch {
                            NSLog("Failed parsing the data")
                        }
                    } else {
                        presentErrorMessage(presentMessage: error!.localizedDescription, layout: .StatusLine)
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
        let blankArray = Array(repeating: [String: Any?](), count: 8)
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
            
            guard !className.contains("Break") else {
                continue
            }

            queue.async(group: group) {
                let lowPriority = course["lowPriority"] as? Int ?? 0

                guard lowPriority == fillLowPriority else {
                    return
                }

                //                When the block is not empty
                let semaphore = DispatchSemaphore.init(value: 0)
                guard var classId = course["id"] as? String else {
                    presentErrorMessage(presentMessage: "Course ID not found", layout: .StatusLine)
                    return
                }
                
                classId = classId.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed)!
                let url = "https://dwei.org/searchbyid/" + classId
                
                let task = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { (data, response, error) in
                    guard error == nil else {
                        presentErrorMessage(presentMessage: error!.localizedDescription, layout: .CardView)
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
                        presentErrorMessage(presentMessage: error.localizedDescription, layout: .StatusLine)
                    }
                    
                    semaphore.signal()
                })
                
                
//                No idea why this does not work.
//                provider.request(MyService.meetTimeSearch(classId: classId), completion: { result in
//                    switch result {
//                    case let .success(response):
//                        do {
//                            guard let meetTimeList = try response.mapJSON() as? Array<String> else {
//                                semaphore.signal()
//                                return
//                            }
//                            
//                            removeIndex += self.writeScheduleToFile(meetTimeList: meetTimeList, course: &course, index: index)
//                            success = true
//                        } catch {
//                            presentErrorMessage(presentMessage: error.localizedDescription, layout: .StatusLine)
//                        }
//                    case let .failure(error):
//                        presentErrorMessage(presentMessage: error.localizedDescription, layout: .CardView)
//                    }
//                    semaphore.signal()
//                })
                
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
            let period = Int(meetTime[1, 1])! - 1
            let fileName = "/Class" + day + ".plist"
            let path = userDocumentPath.appending(fileName)
            
            guard var classOfDay = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
                continue
            }
            
            let classOfThePeriod = classOfDay[period]
            
            if classOfThePeriod.count == 0 {
                course["period"] = period + 1
                classOfDay[period] = course
                NSArray(array: classOfDay).write(toFile: path, atomically: true)
            } else if className.characters.count >= 10 && className[0, 9] == "Study Hall" {
                //                                        It is possible that a study hall that the user doesn't take appear on the course list.
                removeIndex.append(index)
            }
        }
        
        return removeIndex
    }

//    Finish creating schedule
    func fillStudyHall(letter: String) {
        let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Class" + letter + ".plist"
        let path = plistPath.appending(fileName)
        let listClasses = NSMutableArray(contentsOfFile: path)
        for periodNumber in 1...8 {
            var periodExists = false
            for items in listClasses! {
                let classes = items as! NSDictionary
                let periodS = classes["period"] as! String
                let period = Int(periodS)
                if period == periodNumber {
                    periodExists = true
                    break
                }
            }
            if !(periodExists) {
                let addData = ["name": "Free", "period": String(describing: periodNumber)]
                listClasses?.add(addData)
            }
        }
        listClasses?.write(toFile: path, atomically: true)
    }

    func versionCheck() {
        let semaphore = DispatchSemaphore.init(value: 0)
        
        let url = URL(string: "https://dwei.org/dataversion")!
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard error ==  nil else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .StatusLine)
                semaphore.signal()
                return
            }
            
            guard let version = String(data: data!, encoding: .utf8) else {
                semaphore.signal()
                return
            }
            
            let versionNumber = Int(version)!
            userDefaults?.set(versionNumber, forKey: "version")
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
