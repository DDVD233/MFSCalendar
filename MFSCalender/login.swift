//
//  login.swift
//  MFSMobile
//
//  Created by David Dai on 8/29/19.
//  Copyright © 2019 David. All rights reserved.
//

import Foundation

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
//
//    guard let usernameTextUrlEscaped = usernameText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
//        return (false, "Cannot convert to url string", "")
//    }
//
//    guard let passwordTextUrlEscaped = passwordText.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed) else {
//        return (false, "Cannot convert to url string", "")
//    }
//
    let accountCheckURL = Preferences().baseURL + "/api/authentication/login"
    let url = NSURL(string: accountCheckURL)
    var request = URLRequest(url: url! as URL)
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.httpMethod = "POST"
    let loginInfo = ["Username": usernameText, "Password": passwordText]
    request.httpBody = try! JSONSerialization.data(withJSONObject: loginInfo, options: [])
    
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
                let presentMessage = (error?.localizedDescription)! + NSLocalizedString(" Please check your internet connection.", comment: "")
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
    let baseURL = Preferences().baseURL
    let domain = baseURL[8, baseURL.count - 1]
    let cookieProps: [HTTPCookiePropertyKey: Any] = [
        HTTPCookiePropertyKey.domain: domain,
        HTTPCookiePropertyKey.path: "/",
        HTTPCookiePropertyKey.name: "t",
        HTTPCookiePropertyKey.value: token
    ]
    
    if let cookie = HTTPCookie(properties: cookieProps) {
        HTTPCookieStorage.shared.setCookie(cookie)
    }
    
    let cookieProps2: [HTTPCookiePropertyKey: Any] = [
        HTTPCookiePropertyKey.domain: domain,
        HTTPCookiePropertyKey.path: "/",
        HTTPCookiePropertyKey.name: "bridge",
        HTTPCookiePropertyKey.value: "action=create&src=webapp&xdb=true"
    ]
    
    if let cookie = HTTPCookie(properties: cookieProps2) {
        HTTPCookieStorage.shared.setCookie(cookie)
    }
}
