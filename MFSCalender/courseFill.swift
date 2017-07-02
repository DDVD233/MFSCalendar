//
//  courseFill.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/5/23.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import NVActivityIndicatorView
import SwiftMessages
import UICircularProgressRing
import LTMorphingLabel
import SwiftyJSON

class courseFillController:UIViewController {
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    @IBOutlet weak var progressView: UICircularProgressRingView!
    @IBOutlet weak var topLabel: LTMorphingLabel!
    @IBOutlet weak var bottomLabel: LTMorphingLabel!
    
    
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
    
//    When they click "import courses".
    func importCourses() -> Bool {
        progressView.setProgress(value: 2, animationDuration: 0.1)
        if self.newGetCourse() {
            fillAdditionalInformarion()
            fillSchedule()
        } else {
            self.dismiss(animated: true)
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
                        self.versionCheck()
                        self.progressView.setProgress(value: 100, animationDuration: 1) {
                            
                            self.topLabel.text = "Success"
                            self.bottomLabel.text = "Successfully updated"
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
                                self.dismiss(animated: true, completion: nil)
                            })
                        }
                        NSLog("Success Filling schedules")
//                        self.fillStudyHall(letter: "A")
//                        self.fillStudyHall(letter: "B")
//                        self.fillStudyHall(letter: "C")
//                        self.fillStudyHall(letter: "D")
//                        self.fillStudyHall(letter: "E")
//                        self.fillStudyHall(letter: "F")
                        userDefaults?.set(true, forKey: "courseInitialized")
                    } else {
                        self.dismiss(animated: true)
                    }
                }
            } else {
                userDefaults?.set(true, forKey: "courseInitialized")
                self.dismiss(animated: true)
            }
        }
    }
    
    
    func getCourse() -> Bool {
        let username = userDefaults?.string(forKey: "username")
        let password = userDefaults?.string(forKey: "password")
        
        var success = false
        let semaphore = DispatchSemaphore.init(value: 0)
        let urlString = "https://dwei.org/classlistdata/" + username! + "/" + password!
        let url = URL(string: urlString)
        //create request.
        let request3 = URLRequest(url: url!)
        let session = URLSession.shared
        let downloadTask = session.downloadTask(with: request3, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                //Temp location:
                print("location:\(String(describing: location))")
                let locationPath = location!.path
                //Copy to User Directory
                let coursePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                let path = coursePath.appending("/CourseList.plist")
                //Init FileManager
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: path) {
                    do {
                        try fileManager.removeItem(atPath: path)
                    } catch {
                        NSLog("File does not exist! (Which is impossible)")
                    }
                }
                try! fileManager.moveItem(atPath: locationPath, toPath: path)
                print("new location:\(path)")
                success = true
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                    let view = MessageView.viewFromNib(layout: .CardView)
                    view.configureTheme(.error)
                    let icon = "🤔"
                    view.configureContent(title: "Error!", body: presentMessage, iconText: icon)
                    view.button?.isHidden = true
                    let config = SwiftMessages.Config()
                    SwiftMessages.show(config: config, view: view)
                }
            }
            semaphore.signal()
        })
        //使用resume方法启动任务
        downloadTask.resume()
        semaphore.wait()
        return success
    }
    
    func newGetCourse() -> Bool {
        var success = false
        let semaphore = DispatchSemaphore.init(value: 0)
        //create request.
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        let session = URLSession.init(configuration: config)
        
        let (loginSuccess, token, userId) = loginAuthentication()
        if loginSuccess {
            let cookieProps: [HTTPCookiePropertyKey : Any] = [
                HTTPCookiePropertyKey.domain: "mfriends.myschoolapp.com",
                HTTPCookiePropertyKey.path: "/",
                HTTPCookiePropertyKey.name: "t",
                HTTPCookiePropertyKey.value: token
            ]
            
            if let cookie = HTTPCookie(properties: cookieProps) {
                HTTPCookieStorage.shared.setCookie(cookie)
            }
        }
        
        let urlString = "https://mfriends.myschoolapp.com/api/datadirect/ParentStudentUserAcademicGroupsGet?userId=\(userId)&schoolYearLabel=2016+-+2017&memberLevel=3&persona=2&durationList=73751"
        
        let url = URL(string: urlString)
        var request = URLRequest(url: url!)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10.12; rv:52.0) Gecko/20100101 Firefox/52.0", forHTTPHeaderField: "User-Agent")
        
        let downloadTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                var courseData = JSON(data: data!).arrayObject
                
                for (index, item) in courseData!.enumerated() {
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
                    courseData?[index] = course
                }
                
                let coursePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                let path = coursePath.appending("/CourseList.plist")
                print(path)
                
                NSArray(array: courseData!).write(toFile: path, atomically: true)
                success = true
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                    let view = MessageView.viewFromNib(layout: .CardView)
                    view.configureTheme(.error)
                    let icon = "🤔"
                    view.configureContent(title: "Error!", body: presentMessage, iconText: icon)
                    view.button?.isHidden = true
                    let config = SwiftMessages.Config()
                    SwiftMessages.show(config: config, view: view)
                }
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
        
        var filledCourse = [NSMutableDictionary]()
        
        for course in courseList {
            guard let courseName = course["className"] as? String else { return }
            print(courseName)
            let teacherName = course["teacherName"] as? String
            print(teacherName ?? "")
            var urlString = "https://dwei.org/course/getAdditionalInformation/\(courseName)/\(teacherName ?? "None")"
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
                            courseToAdd.addEntries(from: infoToAdd as! [String : Any])
                            filledCourse.append(courseToAdd)
                        }
                        
                    } catch {
                        NSLog("Failed parsing the data")
                    }
                } else {
                    DispatchQueue.main.async {
                        let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                        let view = MessageView.viewFromNib(layout: .CardView)
                        view.configureTheme(.error)
                        let icon = "🤔"
                        view.configureContent(title: "Error!", body: presentMessage, iconText: icon)
                        view.button?.isHidden = true
                        let config = SwiftMessages.Config()
                        SwiftMessages.show(config: config, view: view)
                    }
                }
                semaphore.signal()
            })
            //使用resume方法启动任务
            downloadTask.resume()
            semaphore.wait()
        }
        
        NSArray(array: filledCourse).write(toFile: path, atomically: true)
    }
    
    func clearData(day:String) {
        let coursePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let fileName = "/Class" + day + ".plist"
        let path = coursePath.appending(fileName)
        let blankArray:NSArray = []
        blankArray.write(toFile: path, atomically: true)
    }
    
    func createSchedule(fillLowPriority:Int) -> Bool {
        var success = false
        let coursePath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = coursePath.appending("/CourseList.plist")
        let coursesObject = NSMutableArray(contentsOfFile: path)!
        var removeIndex:IndexSet = []
        for (index, items) in coursesObject.enumerated() {
            guard let courses = items as? NSDictionary else {
                break
            }
//            let block = courses["block"] as? String ?? ""
            let className = courses["className"] as? String
            let teacherName = courses["teacherName"] as? String
            let roomNumber = courses["roomNumber"] as? String
            let lowPriority = courses["lowPriority"] as? Int ?? 0
            if lowPriority == fillLowPriority {
//                When the block is not empty
                let semaphore = DispatchSemaphore.init(value: 0)
                var courseCheckURL:String? = nil
//                如果有block用查Block的方法，否则直接查课。
//                if !block.isEmpty {
//                courseCheckURL = "https://dwei.org/classmeettime/" + block
//                } else {
                var classId = courses["id"] as! String
                classId = classId.replacingOccurrences(of: " ", with: "%20")
                print(classId)
                courseCheckURL = "https://dwei.org/searchbyid/" + classId
//                }
                let url = NSURL(string: courseCheckURL!)
                let request = URLRequest(url: url! as URL)
                let session = URLSession.shared
                success = false
                //Task 1: Getting day data.
                let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
                    
                    if error == nil {
                        do {
                            let resDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? NSArray
                            let plistPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
//                            遍历所有的meet time， 格式为day + period
                            for items in resDict! {
                                print(items)
                                guard let meetTime = items as? String else {
                                    continue
                                }
                                
                                guard !meetTime.isEmpty else {
                                    continue
                                }
                                let day = meetTime[0,0]
                                let period = meetTime[1,1]
                                let fileName = "/Class" + day + ".plist"
                                let path = plistPath.appending(fileName)
                                let classOfDay = NSMutableArray(contentsOfFile: path)
                                var writeFile = true
                                if classOfDay != nil {
                                    for items in classOfDay! {
                                        let classes = items as! NSDictionary
                                        if (classes["period"] as! String) == period {
                                            writeFile = false
                                        }
                                    }
                                }
                                if writeFile {
                                    let AddData = ["name": className, "period": period, "room": roomNumber, "teacherName": teacherName ?? ""]
                                    //                          添加数据
                                    classOfDay?.add(AddData)
                                    classOfDay?.write(toFile: path, atomically: true)
                                } else {
                                    if ((className?.characters.count)! >= 10)  && (className?[0,9] == "Study Hall") {
                                        removeIndex.insert(index)
                                    }
                                }
                            }
                            success = true
                        } catch {
                            NSLog("Data parsing failed")
                        }
                    } else {
//                        When it fails because of the internet.
                        DispatchQueue.main.async {
                            let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                            let view = MessageView.viewFromNib(layout: .CardView)
                            view.configureTheme(.error)
                            let icon = "🤔"
                            view.configureContent(title: "Error!", body: presentMessage, iconText: icon)
                            view.button?.isHidden = true
                            let config = SwiftMessages.Config()
                            SwiftMessages.show(config: config, view: view)
                        }
                    }
                    semaphore.signal()
                })
                
                task.resume()
                semaphore.wait()
            }
        }
        
        if fillLowPriority == 1 {
            coursesObject.removeObjects(at: removeIndex)
            coursesObject.write(toFile: path, atomically: true)
        }
        return success
    }
//    Finish creating schedule
    func fillStudyHall(letter:String) {
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
                if period == periodNumber  {
                    periodExists = true
                    break
                }
            }
            if !(periodExists) {
                let addData = ["name": "Free", "period": String(describing:periodNumber)]
                listClasses?.add(addData)
            }
        }
        listClasses?.write(toFile: path, atomically: true)
    }
    
    func versionCheck() {
        //version check.
        let semaphore = DispatchSemaphore.init(value: 0)
        let versionCheckURL = "https://dwei.org/dataversion"
        let versionUrl = NSURL(string: versionCheckURL)
        let versionRequest = URLRequest(url: versionUrl! as URL)
        let session = URLSession.shared
        let task: URLSessionDataTask = session.dataTask(with: versionRequest, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            NSLog("Done")
            
            if error == nil {
                guard let version = String(data: data!, encoding: .utf8) else {
                    return
                }
                let versionNumber = Int(version)
                print("Version: ", versionNumber!)
                userDefaults?.set(versionNumber, forKey: "version")
                NSLog("Data refreshed to %#", version)
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)!
                    let view = MessageView.viewFromNib(layout: .StatusLine)
                    view.configureTheme(.error)
                    view.configureContent(body: presentMessage)
                    var config = SwiftMessages.Config()
                    config.presentationContext = .window(windowLevel: UIWindowLevelStatusBar)
                    config.preferredStatusBarStyle = .lightContent
                    SwiftMessages.show(config: config, view: view)
                }
                NSLog("error: %@", error!.localizedDescription)
                NSLog("最外层的错误")
            }
            semaphore.signal()
        })
        
        task.resume()
        semaphore.wait()
    }
}
