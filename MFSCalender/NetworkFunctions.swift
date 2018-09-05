//
//  NetworkFunctions.swift
//  MFSMobile
//
//  Created by David Dai on 6/5/18.
//  Copyright © 2018 David. All rights reserved.
//

import UIKit
import Alamofire
import JSQWebViewController
import SafariServices

class NetworkOperations {
    func getQuarterSchedule() {
        provider.request(MyService.getQuarterSchedule, callbackQueue: DispatchQueue.global()) { (result) in
            switch result {
            case let .success(response):
                do {
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? [[String: String]] else {
                        presentErrorMessage(presentMessage: "Quarter Data not found", layout: .cardView)
                        return
                    }
                    
                    print(json)
                    
                    let quarterScheduleFile = userDocumentPath.appending("/QuarterSchedule.plist")
                    NSArray(array: json).write(toFile: quarterScheduleFile, atomically: true)
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.errorDescription!, layout: .cardView)
            }
        }
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
