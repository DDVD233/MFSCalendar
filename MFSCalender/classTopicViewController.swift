//
//  classTopicViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/7/2.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import SwiftMessages
import SDWebImage
import DGElasticPullToRefresh

class classTopicViewController: UIViewController {
    @IBOutlet var topicsCollectionView: UICollectionView!
    var pagerViewController: UIViewController? = nil
    
    var topicsList = [Dictionary<String, Any>]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        topicsCollectionView.delegate = self
        topicsCollectionView.dataSource = self
        
        DispatchQueue.global().async {
            let leadSectionIdInt = self.getTheClassToPresent()
            
            let fileManager = FileManager.default
            
            let path = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
            let topicPath = path.appending("/topics_\(String(leadSectionIdInt)).plist")
            
            if fileManager.fileExists(atPath: topicPath) {
                if let dataFromFile = NSArray(contentsOfFile: topicPath) as? Array<Dictionary<String, Any>> {
                    self.topicsList = dataFromFile
                    DispatchQueue.main.async {
                        self.topicsCollectionView.reloadData()
                    }
                    return
                }
            }
            
            self.refreshTopics(leadSectionIdInt: leadSectionIdInt)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let loadingview = DGElasticPullToRefreshLoadingViewCircle()
        loadingview.tintColor = UIColor.white
        topicsCollectionView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            let leadSectionIdInt = self?.getTheClassToPresent() ?? 0
            self?.refreshTopics(leadSectionIdInt: leadSectionIdInt)
            //            self?.semaphore.wait()
            self?.topicsCollectionView.dg_stopLoading()
            }, loadingView: loadingview)
        topicsCollectionView.dg_setPullToRefreshFillColor(UIColor(hexString: 0xFF7E79))
        topicsCollectionView.dg_setPullToRefreshBackgroundColor(topicsCollectionView.backgroundColor!)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        topicsCollectionView.dg_removePullToRefresh()
    }
    
    func refreshTopics(leadSectionIdInt: Int) {
        guard leadSectionIdInt != 0 else {
            return
        }
        
        self.getTopics(leadSectionIdInt: leadSectionIdInt)
        DispatchQueue.main.async {
            self.topicsCollectionView.reloadData()
        }
    }
    
    func getTopics(leadSectionIdInt: Int) {
        guard loginAuthentication().success else {
            return
        }
        
        let url = "https://mfriends.myschoolapp.com/api/datadirect/sectiontopicsget/\(String(leadSectionIdInt))/?format=json&active=true&future=false&expired=false&sharedTopics=false"
        
        let session = URLSession.shared
        let request = URLRequest(url: URL(string: url)!)
        let semaphore = DispatchSemaphore.init(value: 0)
        
        let task = session.dataTask(with: request, completionHandler: {(data, response, error) -> Void in
            if error == nil {
                do {
                    if var json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Array<Dictionary<String, Any>> {
                        self.topicsList = json
                        print(json)
                        
//                        Remove all the null values because plist file does not accept that.
                        for (index, item) in json.enumerated() {
                            var revisedTopic = item
                            for (key, value) in item {
                                if (value as? NSNull) == NSNull() {
                                    revisedTopic[key] = ""
                                }
                            }
                            
                            json[index] = revisedTopic
                        }
                        
                        let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                        let topicPath = path.appending("/topics_\(String(leadSectionIdInt)).plist")
                        NSArray(array: json).write(toFile: topicPath, atomically: true)
                    }
                } catch {
                    NSLog("JSON parse failed")
                }
            } else {
                DispatchQueue.main.async {
                    let presentMessage = (error?.localizedDescription)! + " Please check your internet connection."
                    let view = MessageView.viewFromNib(layout: .CardView)
                    view.configureTheme(.error)
                    let icon = "😱"
                    view.configureContent(title: "Error!", body: presentMessage, iconText: icon)
                    view.button?.isHidden = true
                    let config = SwiftMessages.Config()
                    SwiftMessages.show(config: config, view: view)
                }
            }
            semaphore.signal()
        })
        
        task.resume()
        semaphore.wait()
    }
    
    func getTheClassToPresent() -> Int {
        let classPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = classPath.appending("/CourseList.plist")
        guard let classList = NSArray(contentsOfFile: path) else {
            return 0
        }
        
        guard let index = userDefaults?.integer(forKey: "indexForCourseToPresent") else {
            return 0
        }
        
        let classObject = classList[index] as! NSDictionary
        
        print(classObject as Any!)
        
        let leadSectionIdInt = classObject["leadsectionid"] as? Int ?? 0
        
        return leadSectionIdInt
    }
}

extension classTopicViewController: UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return topicsList.count
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let viewSize = UIScreen.main.bounds.size.width / 2
        return CGSize(width: viewSize, height: viewSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "classTopicsCell", for: indexPath) as! classTopicsCell
        let topicObject = topicsList[indexPath.row]
        
        cell.topicTitle.text = topicObject["Name"] as? String ?? ""
        
        if let imageName = topicObject["ThumbFilename"] as? String {
            if !imageName.isEmpty {
                cell.backgroundImage.isHidden = false
                cell.darkCover.isHidden = false
                let imageUrl = "https://bbk12e1-cdn.myschoolcdn.com/ftpimages/736/topics/" + imageName
                cell.backgroundImage.sd_setImage(with: URL(string: imageUrl)!)
            } else {
                cell.backgroundImage.isHidden = true
                cell.darkCover.isHidden = true
            }
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let topicObject = topicsList[indexPath.row]
        
        if let topicID = topicObject["TopicID"] as? Int {
            userDefaults?.set(topicID, forKey: "topicID")
        }
        
        if let topicIndexID = topicObject["TopicIndexID"] as? Int {
            userDefaults?.set(topicIndexID, forKey: "topicIndexID")
        }
        
        if let topicDetailViewController = storyboard?.instantiateViewController(withIdentifier: "topicDetailViewController") {
            navigationController?.show(topicDetailViewController, sender: self)
        }
    }
}

extension classTopicViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "TOPICS")
    }
}

class classTopicsCell: UICollectionViewCell {
    @IBOutlet var backgroundImage: UIImageView!
    @IBOutlet var topicTitle: UILabel!
    @IBOutlet var darkCover: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        backgroundImage.contentMode = .scaleAspectFill
    }
}
