//
//  UIView+O2CornerRadius.swift
//  MFSCalender
//
//  Created by 戴元平 on 2017/3/26.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import SwiftMessages

extension UIView {
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        // also  set(newValue)
        set {
            layer.cornerRadius = newValue
        }
    }

}

extension String {
    func replace(target: String, withString: String) -> String {
        return self.replacingOccurrences(of: target, with: withString, options: NSString.CompareOptions.literal, range: nil)
    }
}

extension String {
    subscript(r: Range<Int>) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: r.lowerBound)
            let endIndex = self.index(self.startIndex, offsetBy: r.upperBound+1)
            
            return self[Range(uncheckedBounds: (startIndex, endIndex))]
        }
    }
    
    subscript(start: Int, end: Int) -> String {
        get {
            let startIndex = self.index(self.startIndex, offsetBy: start)
            let endIndex = self.index(self.startIndex, offsetBy: end+1)
            return self[Range(uncheckedBounds: (startIndex, endIndex))]
        }
    }
}

extension UIColor {
    public convenience init(hexString: UInt32, alpha: CGFloat = 1.0) {
        let red     = CGFloat((hexString & 0xFF0000) >> 16) / 255.0
        let green   = CGFloat((hexString & 0x00FF00) >> 8 ) / 255.0
        let blue    = CGFloat((hexString & 0x0000FF)      ) / 255.0
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
}


extension UIView
{
    func copyView() -> AnyObject
    {
        return NSKeyedUnarchiver.unarchiveObject(with: NSKeyedArchiver.archivedData(withRootObject: self))! as AnyObject
    }
}


extension UIImage {
    
    func imageResize (sizeChange:CGSize)-> UIImage{
        
        let hasAlpha = true
        let scale: CGFloat = 0.0 // Use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(sizeChange, !hasAlpha, scale)
        self.draw(in: CGRect(origin: CGPoint.zero, size: sizeChange))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        return scaledImage!
    }
    
}

extension UITableView {
    func reloadData(with animation: UITableViewRowAnimation) {
        reloadSections(IndexSet(integersIn: 0..<numberOfSections), with: animation)
    }
}

public let userDefaults = UserDefaults(suiteName: "group.org.dwei.MFSCalendar")

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
            
            let cookieProps: [HTTPCookiePropertyKey : Any] = [
                HTTPCookiePropertyKey.domain: "mfriends.myschoolapp.com",
                HTTPCookiePropertyKey.path: "/",
                HTTPCookiePropertyKey.name: "t",
                HTTPCookiePropertyKey.value: token!
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
            
            return (success, token!, userID!)
        }
    }
    
    let accountCheckURL = "https://mfriends.myschoolapp.com/api/authentication/login/?username=" + usernameText + "&password=" + passwordText + "&format=json"
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
        
        let cookieProps: [HTTPCookiePropertyKey : Any] = [
            HTTPCookiePropertyKey.domain: "mfriends.myschoolapp.com",
            HTTPCookiePropertyKey.path: "/",
            HTTPCookiePropertyKey.name: "t",
            HTTPCookiePropertyKey.value: token!
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
    
    return (success, token!, userID!)
}

public func presentErrorMessage(presentMessage: String) {
    let view = MessageView.viewFromNib(layout: .CardView)
    view.configureTheme(.error)
    let icon = "😱"
    view.configureContent(title: "Error!", body: presentMessage, iconText: icon)
    view.button?.isHidden = true
    let config = SwiftMessages.Config()
    SwiftMessages.show(config: config, view: view)
}
