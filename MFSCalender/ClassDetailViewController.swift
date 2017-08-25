//
//  ClassDetailViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/6/22.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import XLPagerTabStrip
import SwiftMessages
import SwiftyJSON
import DGElasticPullToRefresh
import Alamofire
import M13ProgressSuite
import SnapKit
import SafariServices

class classDetailViewController: UITableViewController, UIDocumentInteractionControllerDelegate {
    
    var classObject: NSDictionary? = nil
    var avaliableInformation = [String]()
    var overrideHeader = [String: String]()
    
    var contentList = [String: [[String: Any?]]]()
    
    @IBOutlet weak var teacherName: UILabel!
    @IBOutlet weak var roomNumber: UILabel!
    
    @IBOutlet var basicInformationView: UIView!
    @IBOutlet var classDetailTable: UITableView!
    
    @IBOutlet weak var profileImageView: UIImageView!
    
    let semaphore = DispatchSemaphore.init(value: 0)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.global().async {
            self.getTheClassToPresent()
            self.loadContent()
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        let loadingview = DGElasticPullToRefreshLoadingViewCircle()
        loadingview.tintColor = UIColor.white
        classDetailTable.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            self?.refreshContent()
            //            self?.semaphore.wait()
            self?.tableView.dg_stopLoading()
            }, loadingView: loadingview)
        classDetailTable.dg_setPullToRefreshFillColor(UIColor(hexString: 0xFF7E79))
        classDetailTable.dg_setPullToRefreshBackgroundColor(tableView.backgroundColor!)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        DispatchQueue.global().async {
            self.refreshContent()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        classDetailTable.dg_removePullToRefresh()
    }
    
    func getTheClassToPresent() {
        let classPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = classPath.appending("/CourseList.plist")
        guard let classList = NSArray(contentsOfFile: path) else {
            return
        }
        
        guard let index = userDefaults?.integer(forKey: "indexForCourseToPresent") else {
            return
        }
        
        classObject = classList[index] as? NSDictionary
        
        print(classObject as Any!)
    }
    
    func loadContent() {
        teacherName.text = classObject?["teacherName"] as? String
        roomNumber.text = classObject?["roomNumber"] as? String
        
        if (!teacherName.text!.isEmpty || !roomNumber.text!.isEmpty) && !avaliableInformation.contains("Basic") {
            //            其中一个不为空,且目前还没有这一项时
            avaliableInformation.append("Basic")
        }
        
        DispatchQueue.main.async {
            self.classDetailTable.reloadData()
        }
    }
    
    func refreshContent() {
        guard loginAuthentication().success else {
            return
        }
        
        roomNumber.text = classObject?["roomNumber"] as? String ?? ""
        teacherName.text = classObject?["teacherName"] as? String ?? ""
        
        if let sectionId = classObject?["leadsectionid"] as? Int {
            DispatchQueue.main.async {
                self.navigationController?.showProgress()
                self.navigationController?.setIndeterminate(true)
                UIApplication.shared.isNetworkActivityIndicatorVisible = true
            }
            
            let sectionIdString = String(describing: sectionId)
            let semaphore = DispatchSemaphore(value: 0)
            
            provider.request(.getPossibleContent(sectionId: sectionIdString), completion: {
                (result) in
                switch result {
                case let .success(response):
                    do {
                        guard let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? Array<Dictionary<String, Any?>> else {
                            presentErrorMessage(presentMessage: "Internal error: Incorrect data format", layout: .StatusLine)
                            return
                        }
                        
                        self.avaliableInformation = ["Basic"]
                        var contentNameList = self.contentIDToName(inputData: json, sectionId: sectionIdString)
                        
                        contentNameList.remove(object: "Photo")
                        
                        self.avaliableInformation += contentNameList
                    } catch {
                        presentErrorMessage(presentMessage: error.localizedDescription, layout: .StatusLine)
                    }
                case let .failure(error):
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .StatusLine)
                }
                
                semaphore.signal()
            })
            
            semaphore.wait()
            
            let group = DispatchGroup()
            for contentName in self.avaliableInformation {
                guard contentName != "Basic" else {
                    continue
                }
                
                DispatchQueue.global().async(group: group, execute: {
                    let semaphore = DispatchSemaphore(value: 0)
                    provider.request(MyService.getClassContentData(contentName: contentName, sectionId: sectionIdString), completion: { result in
                        switch result {
                        case let .success(response):
                            do {
                                let json = try response.mapJSON() as? Array<Dictionary<String, Any?>>
                                self.contentList[contentName] = json
                            } catch {
                                presentErrorMessage(presentMessage: error.localizedDescription, layout: .StatusLine)
                            }
                        case let .failure(error):
                            presentErrorMessage(presentMessage: error.localizedDescription, layout: .StatusLine)
                        }
                        semaphore.signal()
                    })
                    
                    semaphore.wait()
                })
            }
            
            group.wait()
            
            DispatchQueue.main.async {
                self.classDetailTable.reloadData()
                self.navigationController?.cancelProgress()
                UIApplication.shared.isNetworkActivityIndicatorVisible = false
            }
        }
    }
    
    func contentIDToName(inputData: Array<Dictionary<String, Any?>>, sectionId: String) -> Array<String> {
        var contentNameList = [String]()
        guard let filePath = Bundle.main.url(forResource: "GroupPossibleContent", withExtension: "plist") else {
            presentErrorMessage(presentMessage: "Resource file missing.", layout: .StatusLine)
            return []
        }
        
        guard let contentLUT = NSArray(contentsOf: filePath) as? Array<Dictionary<String, Any?>> else {
            presentErrorMessage(presentMessage: "Resource file has incorrect format", layout: .StatusLine)
            return []
        }
        
        for items in inputData {
            guard let contentId = items["ContentId"] as? Int else {
                continue
            }
            
            if let nameForTheContent = contentLUT.filter({ $0["ContentId"] as? Int == contentId }).first?["Content"] as? String {
                contentNameList.append(nameForTheContent)
                if let settingString = items["GenericSettings"] as? String {
                    if let setting = settingString.convertToDictionary() {
                        if let thisOverrideHeader = setting["HeaderText"] as? String {
                            overrideHeader[nameForTheContent] = thisOverrideHeader
                        }
                    }
                }
            }
        }
        
        return contentNameList
    }
}

extension classDetailViewController: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "OVERVIEW") 
    }
}

extension classDetailViewController {
//    Tableview delegate & datasource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return avaliableInformation.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch avaliableInformation[section] {
        case "Basic":
            return 1
        default:
            return contentList[avaliableInformation[section]]?.count ?? 0
        }
    }
    
    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if avaliableInformation[indexPath.section] == "Basic" {
            return 130
        }
        
        return UITableViewAutomaticDimension
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: "homeworkTableHeader") as! homeworkTableHeader
        
        let headerText = avaliableInformation[section]
        
        if overrideHeader[headerText] != nil {
            headerView.titleLabel.text = overrideHeader[headerText]
        } else {
            headerView.titleLabel.text = headerText
        }
        
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 46
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section
        
        switch avaliableInformation[section] {
        case "Basic":
            let cell = classDetailTable.dequeueReusableCell(withIdentifier: "classOverviewTable", for: indexPath)
            let sectionId = classObject?["leadsectionid"] as! Int
            let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
            let path = photoPath.appending("/\(sectionId)_profile.png")
            profileImageView.image = UIImage(contentsOfFile: path)
            profileImageView.contentMode = UIViewContentMode.scaleAspectFill
            profileImageView.clipsToBounds = true
            
            cell.selectionStyle = .none
            
            basicInformationView.frame = CGRect(x: 0, y: 1, width: cell.frame.size.width, height: cell.frame.size.height - 2)
            cell.addSubview(basicInformationView)
            cell.layoutSubviews()
            
            return cell
        case "Syllabus":
            var cell = tableView.dequeueReusableCell(withIdentifier: "syllabusCell", for: indexPath) as! syllabusView
        
            handleCellData(cell: &cell, buttonTitleKey: "ShortDescription", textViewTextKey: "Description", indexPath: indexPath)
            
            return cell
        case "Link":
            var cell = tableView.dequeueReusableCell(withIdentifier: "syllabusCell", for: indexPath) as! syllabusView
            
            handleCellData(cell: &cell, buttonTitleKey: "ShortDescription", textViewTextKey: "Description", indexPath: indexPath)
            
            return cell
        case "Announcement":
            var cell = tableView.dequeueReusableCell(withIdentifier: "syllabusCell", for: indexPath) as! syllabusView
            
            handleCellData(cell: &cell, buttonTitleKey: "Name", textViewTextKey: "Description", indexPath: indexPath)
            
            return cell
        case "Download":
            var cell = tableView.dequeueReusableCell(withIdentifier: "syllabusCell", for: indexPath) as! syllabusView
            
            handleCellData(cell: &cell, buttonTitleKey: "Description", textViewTextKey: "LongDescription", indexPath: indexPath)
            
            return cell
        case "Text":
            var cell = tableView.dequeueReusableCell(withIdentifier: "syllabusCell", for: indexPath) as! syllabusView
            
            handleCellData(cell: &cell, buttonTitleKey: "Description", textViewTextKey: "LongText", indexPath: indexPath)
            
            return cell
        case "Expectation":
            var cell = tableView.dequeueReusableCell(withIdentifier: "syllabusCell", for: indexPath) as! syllabusView
            
            handleCellData(cell: &cell, buttonTitleKey: "", textViewTextKey: "ShortDescription", indexPath: indexPath)
            
            return cell
        default:
            break
        }
        
        return UITableViewCell()
    }
    
    func handleCellData(cell: inout syllabusView, buttonTitleKey: String, textViewTextKey: String, indexPath: IndexPath) {
        let sectionName = avaliableInformation[indexPath.section]
        guard let dictData = contentList[sectionName]?[indexPath.row] else {
            return
        }
        
        cell.attachmentQueryString = dictData["AttachmentQueryString"] as? String
        var attachmentFileName: String? {
            if  dictData["Attachment"] is String {
                return dictData["Attachment"] as? String
            } else if dictData["FileName"] is String {
                return dictData["FileName"] as? String
            } else {
               return nil
            }
        }
        
        cell.attachmentFileName = attachmentFileName
        cell.directDownloadUrl = dictData["DownloadUrl"] as? String
        
        cell.url = dictData["Url"] as? String
        
        let titleString = dictData[buttonTitleKey] as? String ?? ""
        cell.title.setTitle(titleString, for: .normal)
        
        if titleString.isEmpty {
            cell.syllabusDescription.snp.makeConstraints({ make in
                make.top.equalTo(cell.snp.topMargin).offset(5)
            })
        } else {
            cell.syllabusDescription.snp.removeConstraints()
        }
        
        let htmlString = dictData[textViewTextKey] as? String ?? ""
        
        if !htmlString.isEmpty {
            if let html = htmlString.convertToHtml() {
                cell.syllabusDescription.attributedText = html
                cell.syllabusDescription.sizeToFit()
            }
        } else {
            cell.syllabusDescription.text = ""
        }
        
//        cell.syllabusDescription.isScrollEnabled = true
//        
//        if cell.syllabusDescription.contentSize.height >= 200 {
//            cell.syllabusDescription.snp.makeConstraints({ (make) in
//                cell.heightConstrant = make.height.equalTo(200).constraint
//            })
//            
//            cell.showMoreView.isHidden = false
//        } else {
//            cell.showMoreView.isHidden = true
//            cell.sizeToFit()
//        }
//    
//        cell.syllabusDescription.isScrollEnabled = false
        
        if cell.url == nil && cell.attachmentFileName == nil {
            cell.title.isEnabled = false
        } else {
            cell.title.isEnabled = true
        }
        
        cell.selectionStyle = .none
    }
}

extension classDetailViewController {
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
        var photolink = ""
        
        let session = URLSession.init(configuration: config)
        
        let dataTask = session.dataTask(with: request3, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                let json = JSON(data: data!)
                if let filePath = json[0]["FilenameUrl"].string {
                    photolink = "https:" + filePath
                } else {
                    NSLog("File path not found. Error code: 13")
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
        //使用resume方法启动任务
        dataTask.resume()
        semaphore.wait()
        return photolink
    }
    
    func getProfilePhoto(photoLink: String, sectionId:String) {
        let url = URL(string: photoLink)
        //create request.
        let request3 = URLRequest(url: url!)
        let semaphore = DispatchSemaphore(value: 0)
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        let session = URLSession.init(configuration: config)
        
        let downloadTask = session.downloadTask(with: request3, completionHandler: { (location: URL?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                //Temp location:
                print("location:\(String(describing: location))")
                let locationPath = location!.path
                //Copy to User Directory
                let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                let path = photoPath.appending("/\(sectionId)_profile.png")
                //Init FileManager
                let fileManager = FileManager.default
                if fileManager.fileExists(atPath: path) {
                    do {
                        try fileManager.removeItem(atPath: path)
                    } catch {
                        NSLog("File does not exist! (Which is impossible)")
                    }
                }
                try! fileManager.moveItem(atPath: locationPath, toPath: path)
                print("new location:\(path)")
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
        //使用resume方法启动任务
        downloadTask.resume()
        semaphore.wait()
    }
    
    func getContent(sectionId: String) {
        guard loginAuthentication().success else {
            return
        }
        
        let urlString = "https://mfriends.myschoolapp.com/api/syllabus/forsection/\(sectionId)/?format=json&active=true&future=false&expired=false"
        let url = URL(string: urlString)
        //create request.
        let request3 = URLRequest(url: url!)
        let semaphore = DispatchSemaphore(value: 0)
        
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .reloadIgnoringLocalCacheData
        config.urlCache = nil
        
        let session = URLSession.init(configuration: config)
        
        let dataTask = session.dataTask(with: request3, completionHandler: { (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error == nil {
                guard let json = JSON(data: data!).arrayObject as? [NSDictionary] else {
                    semaphore.signal()
                    return
                }
                
                var arrayToWrite = [NSDictionary]()
                
                for items in json {
                    let dictToAdd: NSMutableDictionary = [:]
                    dictToAdd["Description"] = items["Description"]
                    dictToAdd["ShortDescription"] = items["ShortDescription"]
                    dictToAdd["Attachment"] = items["Attachment"]
                    dictToAdd["AttachmentQueryString"] = items["AttachmentQueryString"]
                    arrayToWrite.append(dictToAdd)
                }
                
                let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
                let path = photoPath.appending("/\(sectionId)_syllabus.plist")
                NSArray(array: arrayToWrite).write(toFile: path, atomically: true)
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
        //使用resume方法启动任务
        dataTask.resume()
        semaphore.wait()
    }
    
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

class syllabusView: UITableViewCell {
    @IBOutlet weak var title: UIButton!
    @IBOutlet var syllabusDescription: UITextView!
    var attachmentQueryString: String? = nil
    var attachmentFileName: String? = nil
    var heightConstrant: Constraint? = nil
    var url: String? = nil
    var directDownloadUrl: String? = nil
    
    @IBOutlet var showMoreView: UIView!
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
        syllabusDescription.delegate = self
        title.setTitleColor(UIColor.darkGray, for: .disabled)
    }
    
    @IBAction func showMoreButtonClicked(_ sender: Any) {
        let thisParentViewController = parentViewController as? classDetailViewController
        DispatchQueue.main.async {
            thisParentViewController?.tableView.beginUpdates()
            self.heightConstrant?.deactivate()
            self.syllabusDescription.sizeToFit()
            self.showMoreView.isHidden = true
            self.layoutIfNeeded()
            thisParentViewController?.tableView.endUpdates()
        }
    }
    
    
    @IBAction func titleClicked(_ sender: Any) {
        DispatchQueue.main.async {
            self.parentViewController!.navigationController?.showProgress()
            self.parentViewController!.navigationController?.setIndeterminate(true)
        }
        
        if self.url != nil {
            if let urlToOpen = URL(string: self.url!) {
                let safariViewController = SFSafariViewController(url: urlToOpen)
                parentViewController?.present(safariViewController, animated: true, completion: nil)
            }
            
            return
        }
        
        guard !self.attachmentFileName!.isEmpty else {
            presentMessage(message: "There is no attachment.")
            self.parentViewController!.navigationController?.cancelProgress()
            return
        }
        
        let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let attachmentPath = path + "/" + self.attachmentFileName!
        NSLog("AttachmentPath: \(attachmentPath)")
        //Init FileManager
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: attachmentPath) {
//          Open the existing attachment.
            NSLog("Attempting to open file: \(self.attachmentFileName!)")
            openFile(fileUrl: URL(fileURLWithPath: attachmentPath))
            return
        }
        
        guard loginAuthentication().success else {
            return
        }
        
        var url: String {
            if directDownloadUrl != nil {
                return "https://mfriends.myschoolapp.com" + directDownloadUrl!
            }
            
            return "https://mfriends.myschoolapp.com/app/utilities/FileDownload.ashx?" + attachmentQueryString!
        }
        
        //        create request.
//        Alamofire Test.
        let destination: DownloadRequest.DownloadFileDestination = { _, _ in
            let fileURL = URL(fileURLWithPath: attachmentPath)
            print(fileURL)
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }

        
        Alamofire.download(url, to: destination).response { response in
//            print(response)
            
            if response.error == nil {
                
                NSLog("Attempting to open file: \(self.attachmentFileName!)")
                self.openFile(fileUrl: URL(fileURLWithPath: attachmentPath))
            } else {
                DispatchQueue.main.async {
                    self.parentViewController!.navigationController?.cancelProgress()
                    let message = response.error!.localizedDescription + " Please check your internet connection."
                    self.presentMessage(message: message)
                }
            }
        }
    }
    
    func openFile(fileUrl: URL) {
        let documentController = UIDocumentInteractionController.init(url: fileUrl)
        
        
        documentController.delegate = parentViewController! as? UIDocumentInteractionControllerDelegate
        
        DispatchQueue.main.async {
            self.parentViewController!.navigationController?.cancelProgress()
            documentController.presentPreview(animated: true)
        }
        
    }
    
    func presentMessage(message: String) {
        let view = MessageView.viewFromNib(layout: .CardView)
        view.configureTheme(.error)
        let icon = "😱"
        view.configureContent(title: "Error!", body: message, iconText: icon)
        view.button?.isHidden = true
        let config = SwiftMessages.Config()
        SwiftMessages.show(config: config, view: view)
    }
}

extension syllabusView: UITextViewDelegate {
    @available(iOS 10.0, *)
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        
        // Because the safari view controller no longer providing shared cookies between Safari, Safari View Controller instances, the app should use safari app to open links instead. (https://github.com/openid/AppAuth-iOS/issues/120)
        if #available(iOS 11.0, *) {
            return true
        }
        
        let safariViewController = SFSafariViewController(url: URL)
        
        parentViewController?.present(safariViewController, animated: true, completion: nil)
        
        return false
    }
}
