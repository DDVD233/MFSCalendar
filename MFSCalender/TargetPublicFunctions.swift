//
//  PublicFunctions.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/8/5.
//  Copyright © 2017 David. All rights reserved.
//

import Foundation
import SwiftMessages
import SwiftyJSON
import Alamofire
import M13Checkbox
import SafariServices
import JSQWebViewController
import Kanna
import CoreData


func areEqual<T:Equatable>(type: T.Type, a: Any?, b: Any?) -> Bool? {
    guard let a = a as? T, let b = b as? T else {
        return nil
    }

    return a == b
}

public func getRequestVerification() -> String? {
    var requestVerification: String? = nil
    
    let url = URL(string: "https://mfriends.myschoolapp.com/app#login")!
    let semaphore = DispatchSemaphore.init(value: 0)
    let task = URLSession.shared.dataTask(with: url, completionHandler: {(data, response, error) in
        semaphore.signal()
    })
    
    task.resume()
    semaphore.wait()
    
    loginAuthentication()
    
    let htmlReqUrl = URL(string: "https://mfriends.myschoolapp.com/app/student#studentmyday/assignment-center")!
    let semaphore2 = DispatchSemaphore.init(value: 0)
    let task2 = URLSession.shared.dataTask(with: htmlReqUrl, completionHandler: {(data, response, error) in
        do {
            let doc = try HTML(html: data!, encoding: .utf8)
            requestVerification = doc
                                  .body?
                                  .xpath("//div[@id = '__AjaxAntiForgery']")
                                  .first?.xpath("//input[@name = '__RequestVerificationToken']")
                                  .first?["value"]
            semaphore2.signal()
        } catch {
            print(error.localizedDescription)
        }
    })
    
    task2.resume()
    semaphore2.wait()
    
    return requestVerification
}

@available(iOS 11.0, *)
func setLargeTitle(on viewController: UIViewController) {
    if let navigationBar = viewController.navigationController?.navigationBar {
        navigationBar.barStyle = .black
        navigationBar.prefersLargeTitles = true
        navigationBar.barTintColor = UIColor(hexString: 0xFF7E79)
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

    let accountCheckURL = Preferences().baseURL + "/api/authentication/login/?username=" + usernameTextUrlEscaped + "&password=" + passwordTextUrlEscaped + "&format=json"
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
        HTTPCookiePropertyKey.domain: Preferences().baseDomain,
        HTTPCookiePropertyKey.path: "/",
        HTTPCookiePropertyKey.name: "t",
        HTTPCookiePropertyKey.value: token
    ]

    if let cookie = HTTPCookie(properties: cookieProps) {
        HTTPCookieStorage.shared.setCookie(cookie)
    }

    let cookieProps2: [HTTPCookiePropertyKey: Any] = [
        HTTPCookiePropertyKey.domain: Preferences().baseDomain,
        HTTPCookiePropertyKey.path: "/",
        HTTPCookiePropertyKey.name: "bridge",
        HTTPCookiePropertyKey.value: "action=create&src=webapp&xdb=true"
    ]

    if let cookie = HTTPCookie(properties: cookieProps2) {
        HTTPCookieStorage.shared.setCookie(cookie)
    }
}

public func presentErrorMessage(presentMessage: String, layout: MessageView.Layout) {
    print("[Error] " + presentMessage)
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

class EventView {
    let formatter = DateFormatter()
    
    func getTimeInterval(rowDict: [String: Any]) -> String {
        let isAllDay = rowDict["isAllDay"] as? Int ?? 0
        if isAllDay == 1 {
            return "All Day"
        } else {
            let tEnd = rowDict["tEnd"] as? Int ?? 0
            updateFormatterFormat(time: tEnd)
            guard let timeEnd = formatter.date(from: String(tEnd)) else {
                return ""
            }
            
            let tStart = rowDict["tStart"] as? Int ?? 0
            updateFormatterFormat(time: tStart)
            guard let timeStart = formatter.date(from: String(tStart)) else {
                return ""
            }
            
            formatter.dateFormat = "h:mm a"
            let startString = formatter.string(from: timeStart)
            let endString = formatter.string(from: timeEnd)
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
        _ = loginAuthentication()
        guard let requestVerification = getRequestVerification() else {
            throw CustomError.NetworkError
        }
        
        print(requestVerification)
        var success = true
        let url = "https://mfriends.myschoolapp.com/api/assignment2/assignmentstatusupdate/?format=json&assignmentIndexId=\(assignmentIndexId)&assignmentStatus=\(assignmentStatus)"
        
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

class NetworkOperations {
    func refreshData() {
        let semaphore = DispatchSemaphore.init(value: 0)
        
        provider.request(MyService.getCalendarData, completion: { result in
            switch result {
            case let .success(response):
                do {
                    guard let dayData = try response.mapJSON(failsOnEmptyData: false) as? Dictionary<String, Any> else {
                        presentErrorMessage(presentMessage: "Incorrect file format for day data", layout: .statusLine)
                        return
                    }
                    
                    let dayFile = userDocumentPath.appending("/Day.plist")
                    
                    print("Info: Day Data refreshed")
                    NSDictionary(dictionary: dayData).write(toFile: dayFile, atomically: true)
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
            }
            
            semaphore.signal()
        })
        
        semaphore.wait()
    }
    
    func getDurationId(for quarter: Int) -> String? {
//        let session = URLSession.shared
//        let request = URLRequest(url: URL(string: "https://dwei.org/currentDurationId")!)
//        var strReturn: String? = nil
//        let semaphore = DispatchSemaphore.init(value: 0)
//
//        let task = session.dataTask(with: request, completionHandler: { (data, _, error) -> Void in
//            if error == nil {
//                strReturn = String(data: data!, encoding: .utf8)
//            }
//            semaphore.signal()
//        })
//
//        task.resume()
//        semaphore.wait()
//        return strReturn
        if Preferences().schoolCode == "CMH" {
            switch quarter {
            case 1, 2:
                return "87782"
            case 3, 4:
                return "87783"
            default:
                return nil
            }
        } else {
            switch quarter {
            case 1:
                return "90656"
            case 2:
                return "90657"
            case 3:
                return "90658"
            case 4:
                return "90659"
            default:
                return nil
            }
        }
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

var managedContext: NSManagedObjectContext? {
    guard let appDelegate =
        UIApplication().delegate as? AppDelegate else {
            return nil
    }
    
    if #available(iOS 10.0, *) {
        let managedContext = appDelegate.persistentContainer.viewContext
        return managedContext
    } else {
        return appDelegate.managedObjectContext
    }
}
