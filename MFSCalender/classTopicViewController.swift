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
import DZNEmptyDataSet
import SVProgressHUD

class classTopicViewController: UIViewController {
    @IBOutlet var topicsCollectionView: UICollectionView!
    var pagerViewController: UIViewController? = nil
    var leadSectionIdInt = 0

    var topicsList = [Dictionary<String, Any>]()

    override func viewDidLoad() {
        super.viewDidLoad()
        topicsCollectionView.delegate = self
        topicsCollectionView.dataSource = self
        topicsCollectionView.emptyDataSetSource = self
        topicsCollectionView.emptyDataSetDelegate = self

        DispatchQueue.global().async {
            let classObject = ClassView().getTheClassToPresent() ?? [String: Any]()
            self.leadSectionIdInt = classObject["sectionid"] as? Int ?? 0

            let fileManager = FileManager.default

            let path = fileManager.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
            let topicPath = path.appending("/topics_\(String(self.leadSectionIdInt)).plist")

            if fileManager.fileExists(atPath: topicPath) {
                if let dataFromFile = NSArray(contentsOfFile: topicPath) as? Array<Dictionary<String, Any>> {
                    self.topicsList = dataFromFile
                    DispatchQueue.main.async {
                        self.topicsCollectionView.reloadData()
                    }
                    return
                }
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        let loadingview = DGElasticPullToRefreshLoadingViewCircle()
        loadingview.tintColor = UIColor.white
        topicsCollectionView.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            if let leadSectionIdInt = self?.leadSectionIdInt {
                self?.refreshTopics(leadSectionIdInt: leadSectionIdInt)
            }
            //            self?.semaphore.wait()
            self?.topicsCollectionView.dg_stopLoading()
        }, loadingView: loadingview)
        topicsCollectionView.dg_setPullToRefreshFillColor(UIColor(hexString: 0xFF7E79))
        topicsCollectionView.dg_setPullToRefreshBackgroundColor(topicsCollectionView.backgroundColor!)

        DispatchQueue.global().async {
            let classObject = ClassView().getTheClassToPresent() ?? [String: Any]()
            self.leadSectionIdInt = classObject["sectionid"] as? Int ?? 0
            self.refreshTopics(leadSectionIdInt: self.leadSectionIdInt)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        topicsCollectionView.dg_removePullToRefresh()
    }

    func refreshTopics(leadSectionIdInt: Int) {
        guard leadSectionIdInt != 0 else {
            return
        }

        DispatchQueue.main.async {
            self.navigationController?.showProgress()
            self.navigationController?.setIndeterminate(true)
            SVProgressHUD.show()
        }

        self.getTopics(leadSectionIdInt: leadSectionIdInt)
        DispatchQueue.main.async {
            self.topicsCollectionView.reloadData()
            self.navigationController?.cancelProgress()
            SVProgressHUD.dismiss()
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

        let task = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            guard error == nil else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
                semaphore.signal()
                return
            }
            
            do {
                guard var json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Array<Dictionary<String, Any>> else {
                    presentErrorMessage(presentMessage: "JSON data has incorrect format.", layout: .statusLine)
                    semaphore.signal()
                    return
                }
                
                self.topicsList = json
                print(json)
                
                //                        Remove all the null values because plist file does not accept that.
                for (index, dict) in json.enumerated() {
                    var newDict = dict
                    newDict.removeNil()
                    json[index] = newDict
                }
                
                let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                let topicPath = path.appending("/topics_\(String(leadSectionIdInt)).plist")
                NSArray(array: json).write(toFile: topicPath, atomically: true)
            } catch {
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
            }
            
            semaphore.signal()
        })

        task.resume()
        semaphore.wait()
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
        let viewSize = Layout().squareSize()
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

        if let topicID = topicObject["TopicID"] as? Int, let topicIndexID = topicObject["TopicIndexID"] as? Int {
            Preferences().topicID = topicID
            Preferences().topicIndexID = topicIndexID
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

extension classTopicViewController: DZNEmptyDataSetSource, DZNEmptyDataSetDelegate {
    func image(forEmptyDataSet scrollView: UIScrollView!) -> UIImage! {
        return UIImage(named: "Topic")
    }
    
    func title(forEmptyDataSet scrollView: UIScrollView!) -> NSAttributedString! {
        let attr = [NSAttributedStringKey.font: UIFont.preferredFont(forTextStyle: UIFontTextStyle.headline)]
        let str = "There is no topic to display."
        return NSAttributedString(string: str, attributes: attr)
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
