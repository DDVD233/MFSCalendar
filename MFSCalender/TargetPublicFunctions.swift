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
import Alamofire
import M13Checkbox
import SafariServices
import JSQWebViewController
import Kanna

func areEqual<T:Equatable>(type: T.Type, a: Any?, b: Any?) -> Bool? {
    guard let a = a as? T, let b = b as? T else {
        return nil
    }

    return a == b
}

//public func getRequestVerification() {
//    let url = URL(string: "https://mfriends.myschoolapp.com/app#login")!
//    let semaphore = DispatchSemaphore.init(value: 0)
//    let task = URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
//        semaphore.signal()
//    })
//    
//    task.resume()
//    semaphore.wait()
//    
//    loginAuthentication()
//    
//    let htmlReqUrl = URL(string: "https://mfriends.myschoolapp.com/app/student")!
//    let task2 = URLSession.shared.dataTask(with: htmlReqUrl, completionHandler: { (data, response, error) in
//        
//    })
//}

@available(iOS 11.0, *)
func setLargeTitle(on viewController: UIViewController) {
    viewController.navigationController?.navigationBar.prefersLargeTitles = true
    viewController.navigationController?.navigationBar.barTintColor = UIColor(hexString: 0xFF7E79)
    //viewController.navigationItem.largeTitleDisplayMode = .never
//    viewController.navigationController?.setBackgroundColor(UIColor(hexString: 0xFF7E79))
    
}

@available(iOS 11.0, *)
func disableLargeTitle(on viewController: UIViewController) {
    viewController.navigationController?.navigationBar.prefersLargeTitles = false
    viewController.navigationController?.navigationBar.barTintColor = UIColor(hexString: 0xFF7E79)
}

public func loginAuthentication() -> (success: Bool, token: String, userId: String) {

    guard let usernameText = Preferences().username else {
        return (false, "Username Not Found", "")
    }
    guard let passwordText = Preferences().password else {
        return (false, "Password Not Found", "")
    }

    var token: String? = ""
    var userID: String? = ""
    var success: Bool = false

    if let loginDate = Preferences().loginTime {
        let now = Date()
        let timeInterval = Int(now.timeIntervalSince(loginDate))

        if (timeInterval < 600) && (timeInterval > 0) {
            success = true
            token = Preferences().token
            userID = Preferences().userID

            addLoginCookie(token: token!)

            return (success, token!, userID!)
        }
    }

    guard let usernameTextUrlEscaped = usernameText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
        return (false, "Cannot convert to url string", "")
    }

    guard let passwordTextUrlEscaped = passwordText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
        return (false, "Cannot convert to url string", "")
    }

    let accountCheckURL = "https://mfriends.myschoolapp.com/api/authentication/login/?username=" + usernameTextUrlEscaped + "&password=" + passwordTextUrlEscaped + "&format=json"
    let url = NSURL(string: accountCheckURL)
    let request = URLRequest(url: url! as URL)

    let config = URLSessionConfiguration.default
    config.requestCachePolicy = .reloadIgnoringLocalCacheData
    config.urlCache = nil

    let session = URLSession.init(configuration: config)

    let semaphore = DispatchSemaphore.init(value: 0)
    let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
        if error == nil {
            do {
                let resDict = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as! NSDictionary
                print(resDict)
                if resDict["Error"] != nil {
                    //                        When error occured. Like the username or password is not correct.
                    print("Login Error!")
                    if (resDict["ErrorType"] as! String) == "UNAUTHORIZED_ACCESS" {
                        token = "Incorrect password"
                    }
                    
                } else {
                    //                      When authentication is success.
                    print(resDict)
                    success = true
                    token = resDict["Token"] as? String
                    userID = String(describing: resDict["UserId"]!)
                    Preferences().token = token
                    Preferences().userID = userID
                    Preferences().loginTime = Date()
                    //print(HTTPCookieStorage.shared.cookies(for: response!.url!))
                }
            } catch {
                NSLog("Data parsing failed")
                DispatchQueue.main.async {
                    token = "Data parsing failed"
                }
            }
        } else {
            DispatchQueue.main.async {
                let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                token = presentMessage
            }

        }
        semaphore.signal()

    })

    task.resume()
    semaphore.wait()

    if success {
        addLoginCookie(token: token!)
    }

    return (success, token!, userID!)
}

public func addLoginCookie(token: String) {
    let cookieProps: [HTTPCookiePropertyKey: Any] = [
        HTTPCookiePropertyKey.domain: "mfriends.myschoolapp.com",
        HTTPCookiePropertyKey.path: "/",
        HTTPCookiePropertyKey.name: "t",
        HTTPCookiePropertyKey.value: token
    ]

    if let cookie = HTTPCookie(properties: cookieProps) {
        HTTPCookieStorage.shared.setCookie(cookie)
    }

    let cookieProps2: [HTTPCookiePropertyKey: Any] = [
        HTTPCookiePropertyKey.domain: "mfriends.myschoolapp.com",
        HTTPCookiePropertyKey.path: "/",
        HTTPCookiePropertyKey.name: "bridge",
        HTTPCookiePropertyKey.value: "action=create&src=webapp&xdb=true"
    ]

    if let cookie = HTTPCookie(properties: cookieProps2) {
        HTTPCookieStorage.shared.setCookie(cookie)
    }
}

public func presentErrorMessage(presentMessage: String, layout: MessageView.Layout) {
    let view = MessageView.viewFromNib(layout: layout)
    view.configureTheme(.error)
    let icon = "😱"
    view.configureContent(title: "Error!", body: presentMessage, iconText: icon)
    view.button?.isHidden = true
    let config = SwiftMessages.Config()
    DispatchQueue.main.async {
        SwiftMessages.show(config: config, view: view)
    }
}

class ClassView {
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
                guard let sectionIdInt = items["leadsectionid"] as? Int else {
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
    
    func getTheClassToPresent() -> Dictionary<String, Any>? {
        let classPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = classPath.appending("/CourseList.plist")
        guard let classList = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
            return nil
        }

        let index = Preferences().indexForCourseToPresent

        if let thisClassObject = classList.filter({ $0["index"] as! Int == index }).first {
            return thisClassObject
        }

        return nil
    }

    func getProfilePhotoLink(sectionId: String) -> String {
        guard loginAuthentication().success else {
            return ""
        }
        let urlString = "https://mfriends.myschoolapp.com/api/media/sectionmediaget/\(sectionId)/?format=json&contentId=31&editMode=false&active=true&future=false&expired=false&contextLabelId=2"
        let url = URL(string: urlString)
        //create request.
        let request3 = URLRequest(url: url!)
        let semaphore = DispatchSemaphore(value: 0)

        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        var photoLink = ""

        let session = URLSession.init(configuration: config)

        let dataTask = session.dataTask(with: request3, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                let json = JSON(data: data!)
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
    
    func getMeetTime(period: Int) -> String {
        switch period {
        case 1: return "8:00AM - 8:42AM"
        case 2: return "8:46AM - 9:28AM"
        case 3: return "9:32AM - 10:32AM"
        case 4: return "10:42AM - 11:24AM"
        case 5: return "11:28AM - 12:10AM"
        case 6: return "12:14PM - 12:56PM"
        case 7: return "1:42PM - 2:23PM"
        case 8: return "2:24PM - 3:10PM"
        default: return "Error!"
        }
    }
}

class EventView {
    let formatter = DateFormatter()
    
    func getTimeInterval(rowDict: [String: Any?]) -> String {
        let isAllDay = rowDict["isAllDay"] as! Int
        if isAllDay == 1 {
            return "All Day"
        } else {
            let tEnd = rowDict["tEnd"] as! Int
            updateFormatterFormat(time: tEnd)
            let timeEnd = formatter.date(from: String(describing: tEnd))
            let tStart = rowDict["tStart"] as! Int
            updateFormatterFormat(time: tStart)
            let timeStart = formatter.date(from: String(describing: tStart))
            formatter.dateFormat = "h:mm a"
            let startString = formatter.string(from: timeStart!)
            let endString = formatter.string(from: timeEnd!)
            return startString + " - " + endString
        }
    }
    
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
            return .unchecked
        }
    }
    
    func updateAssignmentStatus(assignmentIndexId: String, assignmentStatus: String) throws {
        var success = true
        let url = "https://mfriends.myschoolapp.com/api/assignment2/assignmentstatusupdate/?format=json&assignmentIndexId=\(assignmentIndexId)&assignmentStatus=\(assignmentStatus)"
        
        let json = ["assignmentIndexId": Int(assignmentIndexId)!, "assignmentStatus": assignmentStatus] as [String : Any]
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json) else {
            return
        }
        
        var request = try! URLRequest(url: URL(string: url)!, method: .post)
        request.httpBody = jsonData
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        let session = URLSession(configuration: config)
        let semaphore = DispatchSemaphore(value: 0)
        
        let task: URLSessionDataTask = session.dataTask(with: request, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                //print(try? JSONSerialization.jsonObject(with: data!, options: .allowFragments))
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

class NetworkOperations {
    func getDurationId() -> String? {
        let session = URLSession.shared
        let request = URLRequest(url: URL(string: "https://dwei.org/currentDurationId")!)
        var strReturn: String? = nil
        let semaphore = DispatchSemaphore.init(value: 0)
        
        let task = session.dataTask(with: request, completionHandler: { (data, _, error) -> Void in
            if error == nil {
                strReturn = String(data: data!, encoding: .utf8)
            }
            semaphore.signal()
        })
        
        task.resume()
        semaphore.wait()
        return strReturn
    }
    
    func loginUsingPost() -> [HTTPCookie]? {
        guard let password = Preferences().password, let username = Preferences().username else {
            return nil
        }
        
        let parameter = ["From":"", "Password": password, "Username": username, "InterfaceSource": "WebApp"]
        print(parameter)
        let jsonData = try! JSONSerialization.data(withJSONObject: parameter, options: .prettyPrinted)
        
        let session = URLSession.shared
        var request = try! URLRequest(url: "https://mfriends.myschoolapp.com/api/SignIn", method: .post)
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
            if #available(iOS 9.0, *) {
                let safariViewController = SFSafariViewController(url: urlToOpen)
                DispatchQueue.main.async {
                    viewController.present(safariViewController, animated: true, completion: nil)
                }
            } else {
                DispatchQueue.main.async {
                    let webViewController = WebViewController(url: urlToOpen)
                    viewController.show(webViewController, sender: viewController)
                }
            }
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

