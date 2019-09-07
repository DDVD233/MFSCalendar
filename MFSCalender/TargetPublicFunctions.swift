//
//  PublicFunctions.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/8/5.
//  Copyright © 2017年 David. All rights reserved.
//

import Foundation
import SwiftMessages
import SwiftyJSON
import SwiftDate
import Alamofire
import M13Checkbox
import SafariServices
import Kanna

func areEqual<T:Equatable>(type: T.Type, a: Any?, b: Any?) -> Bool? {
    guard let a = a as? T, let b = b as? T else {
        return nil
    }

    return a == b
}

public func getRequestVerification() -> String? {
    var requestVerification: String? = nil
    
    let url = URL(string: Preferences().baseURL + "/app#login")!
    let semaphore = DispatchSemaphore.init(value: 0)
    let task = URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
        let _ = loginAuthentication()
        let htmlReqUrl = URL(string: Preferences().baseURL + "/app/student#studentmyday/assignment-center")!
        
        let task2 = URLSession.shared.dataTask(with: htmlReqUrl, completionHandler: {(data, response, error) in
            do {
                let doc = try HTML(html: data ?? Data(), encoding: .utf8)
                requestVerification = doc
                    .body?
                    .xpath("//div[@id = '__AjaxAntiForgery']")
                    .first?.xpath("//input[@name = '__RequestVerificationToken']")
                    .first?["value"]
                semaphore.signal()
            } catch {
                print(error.localizedDescription)
                semaphore.signal()
            }
        })
        
        task2.resume()
    })
    
    task.resume()
    semaphore.wait()
    
    return requestVerification
}

@available(iOS 11.0, *)
func setLargeTitle(on viewController: UIViewController) {
    if let navigationBar = viewController.navigationController?.navigationBar {
        navigationBar.barStyle = .black
        navigationBar.prefersLargeTitles = true
        navigationBar.barTintColor = UIColor(hexString: 0xFF7E79)
//        if #available(iOS 13.0, *) {
//            let navBarAppearance = UINavigationBarAppearance()
//            navBarAppearance.configureWithOpaqueBackground()
//            navBarAppearance.backgroundColor = UIColor(hexString: 0xFF7E79)
//            navBarAppearance.titleTextAttributes = [.foregroundColor: UIColor.white]
//            navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
//            navBarAppearance.shadowColor = nil // line
//            navigationBar.scrollEdgeAppearance = navBarAppearance
//            navigationBar.standardAppearance = navBarAppearance
//        }
        //viewController.navigationItem.largeTitleDisplayMode = .never
        //    viewController.navigationController?.setBackgroundColor(UIColor(hexString: 0xFF7E79))
    } else {
        print("Navigation bar not found")
    }
}

@available(iOS 11.0, *)
func disableLargeTitle(on viewController: UIViewController) {
    viewController.navigationController?.navigationBar.prefersLargeTitles = false
    viewController.navigationController?.navigationBar.barTintColor = UIColor(hexString: 0xFF7E79)
}

public func presentErrorMessage(presentMessage: String, layout: MessageView.Layout) {
    let view = MessageView.viewFromNib(layout: layout)
    view.configureTheme(.error)
    let icon = "😱"
    view.configureContent(title: "Error!", body: presentMessage, iconText: icon)
    print("[ERROR] " + presentMessage)
    view.button?.isHidden = true
    let config = SwiftMessages.Config()
    DispatchQueue.main.async {
        SwiftMessages.show(config: config, view: view)
    }
}

class ClassView {
    func getLeadSectionID(classDict: [String: Any]) -> Int? {
        if let leadSectionID = classDict["leadsectionid"] as? Int {
            return leadSectionID
        } else if let sectionID = classDict["sectionid"] as? Int {
            return sectionID
        } else {
            return nil
        }
    }
    
    func getMarkingPeriodID(durationID: String, leadSectionID: String, completion: @escaping (Int) -> Void) {
        let userID = loginAuthentication().userId
        let personaId = Preferences().personaId ?? "2"
        let url = Preferences().baseURL +  "/api/gradebook/GradeBookMyDayMarkingPeriods?durationSectionList=[{\"DurationId\":\(durationID),\"LeadSectionList\":[{\"LeadSectionId\":\(leadSectionID)}]}]&userId=\(userID)&personaId=\(personaId)"
        print(url)
        let escapedURL = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
//        print
        
        let task = URLSession.shared.dataTask(with: URL(string: escapedURL)!) { (data, response, error) in
            guard error == nil else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
                completion(0)
                return
            }
            do {
                guard let json = try JSONSerialization.jsonObject(with: data ?? Data(), options: .allowFragments) as? [[String: Any]] else {
                    presentErrorMessage(presentMessage: "JSON incorrect format", layout: .statusLine)
                    completion(0)
                    return
                }
                
                print(json)
                
                if json.count == 0 {
                    completion(0)
                }
                
                completion(json[0]["MarkingPeriodId"] as? Int ?? 0)
                return
            } catch {
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                
            }
            
            completion(0)
        }
        
        task.resume()
    }
    
    func getLeadSectionIDFromSectionInfo(sectionID: String) -> String {
        let semaphoreSectionID = DispatchSemaphore(value: 0)
        var sectionID = sectionID
        
        provider.request(.sectionInfoView(sectionID: sectionID), callbackQueue: DispatchQueue.global(), completion: {
            (result) in
            switch result {
            case let .success(response):
                do {
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? Array<Dictionary<String, Any>> else {
                        presentErrorMessage(presentMessage: "Internal error: Incorrect data format", layout: .statusLine)
                        semaphoreSectionID.signal()
                        return
                    }
                    
                    guard json.count > 0 else {
                        presentErrorMessage(presentMessage: "Unable to find section ID.", layout: .statusLine)
                        semaphoreSectionID.signal()
                        return
                    }
                    
                    if let leadSectionID = json[0]["LeadSectionId"] as? Int {
                        sectionID = String(describing: leadSectionID)
                    }
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
            }
            
            semaphoreSectionID.signal()
        })
        
        semaphoreSectionID.wait()
        return sectionID
    }
    
    func getProfilePhoto() {
        let coursePath = FileList.courseList.filePath
        
        guard let courseList = NSArray(contentsOfFile: coursePath) as? Array<Dictionary<String, Any>> else {
            return
        }
        let group = DispatchGroup()
        let queue = DispatchQueue.global()
        
        for items in courseList {
            queue.async(group: group) {
                guard let sectionIdInt = ClassView().getLeadSectionID(classDict: items) else {
                    return
                }
                
                guard let photoURLPath = self.getProfilePhotoLink(sectionId: String(describing: sectionIdInt)) else {
                    NSLog("\(items["coursedescription"] as? String ?? "") has no photo.")
                    return
                }
                
                guard loginAuthentication().success else {
                    return
                }
                
                let sectionId = String(sectionIdInt)
                
                //let photoLink = "https://bbk12e1-cdn.myschoolcdn.com/736/photo/" + photoURLPath
                
                guard let url = URL(string: photoURLPath) else { return }
                
                let downloadSemaphore = DispatchSemaphore.init(value: 0)
                
                let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                    let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                    let photoPath = path.appending("/\(sectionId)_profile.png")
                    
                    let fileURL = URL(fileURLWithPath: photoPath)
                    print(fileURL)
                    
                    downloadSemaphore.signal()
                    
                    return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
                }
                
                
                Alamofire.download(url, to: destination).resume()
                downloadSemaphore.wait()
            }
        }
        
        group.wait()
    }
    
    func getTheClassToPresent() -> Dictionary<String, Any>? {
        let path = FileList.courseList.filePath
        guard let classList = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
            return nil
        }

        let index = Preferences().indexForCourseToPresent
        
        print(classList)

        if classList.indices.contains(index) {
            return classList[index]
        }

        return nil
    }

    func getProfilePhotoLink(sectionId: String) -> String? {
        guard loginAuthentication().success else {
            return ""
        }
        let urlString = Preferences().baseURL + "/api/media/sectionmediaget/\(sectionId)/?format=json&contentId=31&editMode=false&active=true&future=false&expired=false&contextLabelId=2"
        let url = URL(string: urlString)
        //create request.
        let request3 = URLRequest(url: url!)
        let semaphore = DispatchSemaphore(value: 0)

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        var photoLink: String? = nil

        let session = URLSession.init(configuration: config)

        let dataTask = session.dataTask(with: request3, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                let json = try! JSON(data: data!)
                if let filePath = json[0]["FilenameUrl"].string {
                    photoLink = "https:" + filePath
                } else {
                    NSLog("File path not found. Error code: 13")
                }
            } else {
                DispatchQueue.main.async {
                    presentErrorMessage(presentMessage: error!.localizedDescription, layout: .cardView)
                }
            }
            semaphore.signal()
        })
        //使用resume方法启动任务
        dataTask.resume()
        semaphore.wait()
        return photoLink
    }
}

class EventView {
    let formatter = DateFormatter()
    
    func getTimeInterval(rowDict: Events) -> String {
        let startDate = rowDict.startDate ?? Date()
        let endDate = rowDict.endDate ?? Date()
        if ((endDate - startDate).hour ?? 23) >= 23 || (((endDate - startDate).minute ?? 0) <= 1) {
            return NSLocalizedString("All Day", comment: "")
        }
        
        formatter.dateFormat = "h:mm a"
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        return startString + " - " + endString
    }
    
    @available(*, deprecated, message: "No longer used")
    private func updateFormatterFormat(time: Int) {
        if time > 99999 {
            formatter.dateFormat = "HHmmss"
        } else {
            formatter.dateFormat = "Hmmss"
        }
    }
}

enum CustomError: Error {
    case NetworkError
}

class HomeworkView {
    func colorForTheType(type: String) -> UIColor {
        switch type {
        case "Homework":
            return UIColor(hexString: 0xF44336) // Red 500
        case "Quiz":
            return UIColor(hexString: 0x2196F3) // Light Blue 500
        case "Test":
            return UIColor(hexString: 0x3F51B5) // Blue 500
        case "Project":
            return UIColor(hexString: 0xFF9800) // Orange 500
        case "Classwork":
            return UIColor(hexString: 0x795548) // Brown 500
        case "Communicative Skills":
            return UIColor(hexString: 0x43A047) // Green 600
        case "Lab":
            return UIColor(hexString: 0x5D4037) // Brown 700
        case "Writing":
            return UIColor(hexString: 0xA1887F) // Brown 300
        default:
            return UIColor(hexString: 0x607D8B) // Grey 500
        }
    }
    
    func checkStateFor(status: Int) -> M13Checkbox.CheckState {
        switch status {
        case -1:
            return .unchecked
        case 1, 4:
            return .checked
        default:
            return .checked
        }
    }
    
    func updateAssignmentStatus(assignmentIndexId: String, assignmentStatus: String) throws {
        _ = loginAuthentication()
        guard let requestVerification = getRequestVerification() else {
            throw CustomError.NetworkError
        }
        
        print(requestVerification)
        var success = true
        let url = Preferences().baseURL + "/api/assignment2/assignmentstatusupdate/?format=json&assignmentIndexId=\(assignmentIndexId)&assignmentStatus=\(assignmentStatus)"
        
        let json = ["assignmentIndexId": Int(assignmentIndexId)!, "assignmentStatus": assignmentStatus] as [String : Any]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            return
        }
        
        var request = try! URLRequest(url: URL(string: url)!, method: .post)
        request.httpBody = jsonData
        
        request.setValue(requestVerification, forHTTPHeaderField: "RequestVerificationToken")
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config)
        let semaphore = DispatchSemaphore(value: 0)
//        print(assignmentIndexId)
//        print(assignmentStatus)
//        print(request.allHTTPHeaderFields)
        
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
//                print(url)
//                print(try? JSONSerialization.jsonObject(with: data!, options: .allowFragments))
//                print(response!)
            } else {
                success = false
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
            }
            
            semaphore.signal()
        })
        
        task.resume()
        semaphore.wait()
        
        guard success else {
            throw CustomError.NetworkError
        }
    }
}



class Layout {
    func squareSize(estimatedWidth: Int = 150) -> CGFloat {
        let screenWidth = UIScreen.main.bounds.size.width
        print(Int(screenWidth))
        let numberOfItems = Int(screenWidth / CGFloat(estimatedWidth))
        let viewSize = screenWidth / CGFloat(numberOfItems)
        
        return viewSize
    }
}

