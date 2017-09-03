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

func areEqual<T:Equatable>(type: T.Type, a: Any?, b: Any?) -> Bool? {
    guard let a = a as? T, let b = b as? T else {
        return nil
    }

    return a == b
}

public func loginAuthentication() -> (success: Bool, token: String, userId: String) {

    guard let usernameText = userDefaults?.string(forKey: "username") else {
        return (false, "Username Not Found", "")
    }
    guard let passwordText = userDefaults?.string(forKey: "password") else {
        return (false, "Password Not Found", "")
    }

    var token: String? = ""
    var userID: String? = ""
    var success: Bool = false

    if let loginDate = userDefaults?.object(forKey: "loginTime") as? Date {
        let now = Date()
        let timeInterval = Int(now.timeIntervalSince(loginDate))
        if timeInterval < 1200 {
            success = true
            token = userDefaults?.string(forKey: "token")
            userID = userDefaults?.string(forKey: "userID")

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
                    success = true
                    token = resDict["Token"] as? String
                    userID = String(describing: resDict["UserId"]!)
                    userDefaults?.set(token, forKey: "token")
                    userDefaults?.set(userID, forKey: "userID")
                    userDefaults?.set(Date(), forKey: "loginTime")
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
    func getTheClassToPresent() -> Dictionary<String, Any>? {
        let classPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = classPath.appending("/CourseList.plist")
        guard let classList = NSArray(contentsOfFile: path) as? Array<Dictionary<String, Any>> else {
            return nil
        }

        guard let index = userDefaults?.integer(forKey: "indexForCourseToPresent") else {
            return nil
        }

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
                    presentErrorMessage(presentMessage: error!.localizedDescription, layout: .CardView)
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
        case 1: return "8:00 - 8:43"
        case 2: return "8:47 - 9:30"
        case 3: return "9:34 - 10:34"
        case 4: return "10:44 - 11:27"
        case 5: return "11:31 - 12:14"
        case 6: return "12:14 - 12:57"
        case 7: return "13:40 - 14:23"
        case 8: return "14:27 - 15: 10"
        default: return "Error!"
        }
    }
}

class EventView {
    let formatter = DateFormatter()
    
    func getTimeInterval(rowDict: [String: Any?]) -> String {
        if (rowDict["isAllDay"] as! Int) == 1 {
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
}

