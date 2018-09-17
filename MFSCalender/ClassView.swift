//
//  MFSClasses.swift
//  MFSMobile
//
//  Created by David Dai on 2/15/18.
//  Copyright © 2018 David. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

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
        let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let coursePath = path.appending("/CourseList.plist")
        
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
        let classPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = classPath.appending("/CourseList.plist")
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
        let urlString = "https://mfriends.myschoolapp.com/api/media/sectionmediaget/\(sectionId)/?format=json&contentId=31&editMode=false&active=true&future=false&expired=false&contextLabelId=2"
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
