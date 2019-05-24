//
//  NetworkFunctions.swift
//  MFSMobile
//
//  Created by David Dai on 6/5/18.
//  Copyright © 2018 David. All rights reserved.
//

import UIKit
import Alamofire
import SafariServices
import SwiftyJSON
import SwiftDate
import CoreData

class NetworkOperations {
    @available(*, deprecated, message: "Use mySchool Method instead")
    func getQuarterSchedule() {
        let semaphore = DispatchSemaphore(value: 0)
        provider.request(MyService.getQuarterSchedule, callbackQueue: DispatchQueue.global()) { (result) in
            switch result {
            case let .success(response):
                do {
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? [[String: Any]] else {
                        presentErrorMessage(presentMessage: "Quarter Data not found", layout: .cardView)
                        return
                    }
                    
                    print(json)
                    
                    let quarterScheduleFile = userDocumentPath.appending("/QuarterSchedule.plist")
                    NSArray(array: json).write(toFile: quarterScheduleFile, atomically: true)
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
                    print(error.localizedDescription)
                }
                
                semaphore.signal()
            case let .failure(error):
                presentErrorMessage(presentMessage: error.errorDescription!, layout: .cardView)
            }
        }
        
        semaphore.wait()
    }
    
    func getCourseFromMyMFS(durationId: String = Preferences().durationID ?? "", completion: @escaping ([[String: Any?]]) -> Void) {
        //create request.
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        let session = URLSession.init(configuration: config)
        
        let (_, _, userId) = loginAuthentication()
        
//        guard let durationId = Preferences().durationID else {
//            return
//        }
        
        let schoolYear = school.getSchoolYear()
        let urlString = Preferences().baseURL + "/api/datadirect/ParentStudentUserAcademicGroupsGet?userId=\(userId)&schoolYearLabel=\(String(schoolYear))+-+\(String(schoolYear + 1))&memberLevel=3&persona=2&durationList=\(durationId)"
        print(urlString)
        
        let url = URL(string: urlString)
        let request = URLRequest(url: url!)
        
        let downloadTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                guard var courseData = try? JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments) as? [[String: Any?]] else {
                    return
                }
                
                for (index, item) in courseData.enumerated() {
                    var course = item
                    print(course)
                    
                    // To Solve compatibility issue
                    course["className"] = course["sectionidentifier"] as? String
                    course["teacherName"] = course["groupownername"] as? String
                    course["index"] = index
                    //   If I do not delete nil value, it will not be able to write to plist.
                    for (key, value) in course {
                        if value == nil {
                            course[key] = ""
                        }
                    }
                    courseData[index] = course
                }
                
                let path = FileList.courseList.filePath
                NSArray(array: courseData).write(to: URL.init(fileURLWithPath: path), atomically: true)
                completion(courseData)
            } else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
            }
        })
        
        downloadTask.resume()
    }
    
    func loginUsingPost() -> [HTTPCookie]? {
        guard let password = Preferences().password, let username = Preferences().username else {
            return nil
        }
        
        let parameter = ["From":"", "Password": password, "Username": username, "InterfaceSource": "WebApp"]
        print(parameter)
        let jsonData = try! JSONSerialization.data(withJSONObject: parameter, options: .prettyPrinted)
        
        let session = URLSession.shared
        var request = try! URLRequest(url: Preferences().baseURL + "/api/SignIn", method: .post)
        request.httpBody = jsonData
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let semaphore = DispatchSemaphore(value: 0)
        var cookie = [HTTPCookie]()
        
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) in
            let json = try! JSONSerialization.jsonObject(with: data!, options: .allowFragments)
            print(json)
            if let thisResponse = response as? HTTPURLResponse {
                cookie = HTTPCookie.cookies(withResponseHeaderFields: thisResponse.allHeaderFields as! [String : String], for: thisResponse.url!)
                semaphore.signal()
            }
        })
        
        task.resume()
        semaphore.wait()
        return cookie
    }
    
    func downloadFile(url: URL, withName fileName: String) -> (filePath: URL?, error: Error?) {
        let semaphore = DispatchSemaphore(value: 0)
        
        let attachmentPath = userDocumentPath + "/" + fileName
        var returnURL: URL? = nil
        var networkError: Error? = nil
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let fileURL = URL(fileURLWithPath: attachmentPath)
            print(fileURL)
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        let queue = DispatchQueue(label: "com.cnoon.response-queue", qos: .utility, attributes: [.concurrent])
        Alamofire.download(url, to: destination).response(queue: queue, completionHandler: { response in
            
            if response.error == nil {
                
                NSLog("Attempting to open file: \(fileName)")
                returnURL = URL(fileURLWithPath: attachmentPath)
            } else {
                networkError = response.error
            }
            
            semaphore.signal()
        })
        
        semaphore.wait()
        
        DispatchQueue.main.async {
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
        
        return (returnURL, networkError)
    }
    
    func openFile(fileUrl: URL, from viewController: UIViewController) {
        let documentController = UIDocumentInteractionController.init(url: fileUrl)
        
        if let delegate = viewController as? UIDocumentInteractionControllerDelegate {
            documentController.delegate = delegate
        }
        
        DispatchQueue.main.async {
            viewController.navigationController?.cancelProgress()
            documentController.presentPreview(animated: true)
        }
        
    }
    
    func openLink(url: inout String, from viewController: UIViewController) {
        if !url.contains("http") {
            url = "http://" + url
        }
        if let urlToOpen = URL(string: url) {
            let safariViewController = SFSafariViewController(url: urlToOpen)
            DispatchQueue.main.async {
                viewController.present(safariViewController, animated: true, completion: nil)
            }
        }
    }
    
    func refreshEvents(completion: @escaping () -> Void = { () in }) {
        guard loginAuthentication().success else {
            completion()
            return
        }
        
        downloadEventIDList { (idList) in
            guard let idListToRequest = idList else {
                presentErrorMessage(presentMessage: "Failed to obtain an id list.", layout: .statusLine)
                return
            }
            
            self.downloadEventsFromMySchool(idList: idListToRequest, completion: completion)
        }
    }
    
    func downloadEventsFromMySchool(idList: [String], completion: @escaping () -> Void) {
        let startDate = Date() - 3.months
        let endDate = Date() + 8.months
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        let startDateString = formatter.string(from: startDate)
        let endDateString = formatter.string(from: endDate)
        let delegate = UIApplication.shared.delegate as! AppDelegate
        let context = delegate.persistentContainer.viewContext
        
        formatter.dateFormat = "M/dd/yyyy h:mm a"
        provider.request(MyService.downloadEventsFromMySchool(startDate: startDateString, endDate: endDateString, idList: idList), callbackQueue: DispatchQueue.global()) { (result) in
            switch result {
            case .success(let response):
                do {
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? [[String: Any]] else {
                        presentErrorMessage(presentMessage: "JSON incorrect format", layout: .statusLine)
                        completion()
                        return
                    }
                    
                    print(response.request?.url)
                    print(json)
                    print(json.count)
                    
                    for event in json {
                        guard let startDate = formatter.date(from: event["StartDate"] as? String ?? "") else {
                            continue
                        }
                        var endDate: Date {
                            if let dateFromString = formatter.date(from: event["EndDate"] as? String ?? "") {
                                return dateFromString
                            } else {
                                return startDate
                            }
                        }
                        guard let title = event["Title"] as? String else {
                            continue
                        }
                        guard let eventId = event["EventId"] as? Int else {
                            continue
                        }
                        
                        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "Events")
                        let predicate = NSPredicate(format: "(eventId == %d)", eventId)
                        
                        fetchRequest.predicate = predicate
                        let res = try! context.fetch(fetchRequest)
                        
                        if res.count == 0 {
                            let entity = NSEntityDescription.entity(forEntityName: "Events", in: context)
                            let newEvent = Events(entity: entity!, insertInto: context)
                            newEvent.setValue(startDate, forKey: "startDate")
                            newEvent.setValue(endDate, forKey: "endDate")
                            newEvent.setValue(title, forKey: "title")
                            print(title)
                            newEvent.setValue(eventId, forKey: "eventId")
                            
                            let briefDescription = event["BriefDescription"] as? String ?? ""
                            newEvent.setValue(briefDescription, forKey: "briefDescription")
                            
                            let location = event["Location"] as? String ?? ""
                            newEvent.setValue(location, forKey: "location")
                            
                            let groupName = event["GroupName"] as? String ?? ""
                            newEvent.setValue(groupName, forKey: "groupName")
                            
                            try! context.save()
                        }
                    }
            
                    completion()
                    return
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
            }
            
            completion()
            return
        }
    }
    
    func downloadEventIDList(completion: @escaping ([String]?) -> Void) {
        let startDate = Date() - 3.months
        let endDate = Date() + 5.months
        
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yyyy"
        let startDateString = formatter.string(from: startDate)
        let endDateString = formatter.string(from: endDate)
        provider.request(MyService.getEventsIDList(startDate: startDateString, endDate: endDateString), callbackQueue: DispatchQueue.global()) { (result) in
            switch result {
            case .success(let response):
                do {
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? [[String: Any]] else {
                        presentErrorMessage(presentMessage: "JSON incorrect format", layout: .statusLine)
                        print(String(data: response.data, encoding: .utf8))
                        completion(nil)
                        return
                    }
                    
                    print(json)
                    var idList = [String]()
                    for calendar in json {
                        guard let filters = calendar["Filters"] as? [[String: Any]] else { continue }
                        for filter in filters {
                            if let calendarId = filter["CalendarId"] as? String {
                                idList.append(calendarId)
                            }
                        }
                    }
                    
                    print(idList)
                    completion(idList)
                    return
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
            }
            
            completion(nil)
            return
        }
    }
    
    func downloadLargeProfilePhoto() {
        if let largeFileLink = userDefaults.string(forKey: "largePhotoLink") {
            provider.request(.downloadLargeProfilePhoto(link: largeFileLink), completion: { result in
                switch result {
                case .success(_):
                    userDefaults.set(true, forKey: "didDownloadFullSizeImage")
                case let .failure(error):
                    NSLog("Failed downloading large profile photo because: \(error)")
                }
            })
        }
    }
    
    func downloadQuarterScheduleFromMySchool(completion: @escaping () -> Void) {
        guard loginAuthentication().success else {
            completion()
            return
        }
        let userID = loginAuthentication().userId
        let schoolYear = school.getSchoolYear()
        let schoolYearLabel = String(schoolYear) + "+-+" + String(schoolYear + 1)
        let url = Preferences().baseURL + "/api/DataDirect/StudentGroupTermList/?studentUserId=\(userID)&schoolYearLabel=\(schoolYearLabel)&personaId=2"
        
        let task = URLSession.shared.dataTask(with: URL(string: url)!) { (data, response, error) in
            guard error == nil else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
                completion()
                return
            }
            
            do {
                guard var json = try JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments) as? [[String: Any]] else {
                    presentErrorMessage(presentMessage: "Quarter File Incorrect Format.", layout: .cardView)
                    completion()
                    return
                }
                
                json.removeAll(where: { ($0["OfferingType"] as? Int ?? 1) != 1 })
                print(json)
//                print(response.request?.url)
                var didFindQuarter = false
                for (index, value) in json.enumerated() {
                    guard let currentIndicator = value["CurrentInd"] as? Int else { continue }
                    if currentIndicator == 1 {
                        didFindQuarter = true
                        let newQuarterOnline = index + 1
                        if newQuarterOnline != Preferences().currentQuarterOnline {
                            // Quarter Changed
                            Preferences().currentQuarterOnline = newQuarterOnline
                            Preferences().courseInitialized = false
                        }
                        
                        Preferences().currentDurationIDOnline = value["DurationId"] as? Int ?? 0
                        Preferences().currentDurationDescriptionOnline = value["DurationDescription"] as? String
                    }
                }
                
                if !didFindQuarter {
                    Preferences().currentQuarterOnline = 1
                    Preferences().currentDurationIDOnline = 0
                    Preferences().currentDurationDescriptionOnline = ""
                }
                
                let quarterFilePath = FileList.quarterSchedule.filePath
                NSArray(array: json).write(toFile: quarterFilePath, atomically: true)
            } catch {
                print(error.localizedDescription)
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
            }
            completion()
        }
        
        task.resume()
    }
}
