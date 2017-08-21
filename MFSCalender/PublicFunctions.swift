//
//  PublicFunctions.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/8/5.
//  Copyright © 2017年 David. All rights reserved.
//

import Foundation
import SwiftMessages

public func loginAuthentication() -> (success:Bool, token:String, userId: String) {
    
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
    let cookieProps: [HTTPCookiePropertyKey : Any] = [
        HTTPCookiePropertyKey.domain: "mfriends.myschoolapp.com",
        HTTPCookiePropertyKey.path: "/",
        HTTPCookiePropertyKey.name: "t",
        HTTPCookiePropertyKey.value: token
    ]
    
    if let cookie = HTTPCookie(properties: cookieProps) {
        HTTPCookieStorage.shared.setCookie(cookie)
    }
    
    let cookieProps2: [HTTPCookiePropertyKey : Any] = [
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
    SwiftMessages.show(config: config, view: view)
}

protocol reusable {
    func getCurrentPeriod(time: Int) -> Int
}

func getCurrentPeriod(time: Int) -> Int {
    let Period1Start = 800
    let Period2Start = 847
    let Period3Start = 934
    let Period4Start = 1044
    let Period5Start = 1131
    let Period6Start = 1214
    let LunchStart   = 1300
    let Period7Start = 1340
    let Period8Start = 1427
    let Period8End   = 1510
    var currentClass: Int? = nil
    
    switch time {
    case 0..<Period1Start:
        NSLog("Period 0")
        currentClass = 1
    case Period1Start..<Period2Start:
        NSLog("Period 1")
        currentClass = 1
    case Period2Start..<Period3Start:
        NSLog("Period 2")
        currentClass = 2
    case Period3Start..<Period4Start:
        NSLog("Period 3")
        currentClass = 3
    case Period4Start..<Period5Start:
        NSLog("Period 4")
        currentClass = 4
    case Period5Start..<Period6Start:
        NSLog("Period 5")
        currentClass = 5
    case Period6Start..<LunchStart:
        NSLog("Period 6")
        currentClass = 6
    case LunchStart..<Period7Start:
        NSLog("Lunch")
        currentClass = 11
    case Period7Start..<Period8Start:
        NSLog("Period 7")
        currentClass = 7
    case Period8Start..<Period8End:
        NSLog("Period 8")
        currentClass = 8
    case Period8End..<3000:
        NSLog("After School.")
        currentClass = 9
    default:
        NSLog("???")
        currentClass = -1
    }
    
    return currentClass!
}

//func removeNill(array: inout Array) {
//    for items in array {
//        if items == nil {
//            array
//        }
//    }
//}

