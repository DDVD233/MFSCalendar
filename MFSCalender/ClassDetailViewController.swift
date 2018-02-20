//
//  ClassDetailViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/6/22.
//  Copyright © 2017 David. All rights reserved.
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
import SVProgressHUD

class classDetailViewController: UITableViewController, UIDocumentInteractionControllerDelegate {

    var classObject = ClassView().getTheClassToPresent() ?? [String: Any]()
    var availableInformation = [String]()
    var sectionShouldShowMore = [String: Bool]()
    var overrideHeader = [String: String]()

    var contentList = [String: [[String: Any?]]]()

    @IBOutlet weak var teacherName: UILabel!
    @IBOutlet weak var roomNumber: UILabel!
    @IBOutlet var courseName: UILabel!
    
    @IBOutlet var basicInformationView: UIView!
    @IBOutlet var classDetailTable: UITableView!

    @IBOutlet weak var profileImageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.loadContent()
    }

    override func viewWillAppear(_ animated: Bool) {
        let loadingView = DGElasticPullToRefreshLoadingViewCircle()
        loadingView.tintColor = UIColor.white
        classDetailTable.dg_addPullToRefreshWithActionHandler({ [weak self] () -> Void in
            DispatchQueue.global().async {
                self?.refreshContent()
            }
            self?.tableView.dg_stopLoading()
        }, loadingView: loadingView)
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

    func loadContent() {

//        if teacherName.text.existsAndNotEmpty() || roomNumber.text.existsAndNotEmpty() && !availableInformation.contains("Basic") {
//            //            其中一个不为空,且目前还没有这一项时
//            availableInformation.append("Basic")
//        }
        
        configureBasicInfoView()
        
        self.classDetailTable.reloadData()
    }
    
    func configureBasicInfoView() {
        if let sectionId = ClassView().getLeadSectionID(classDict: classObject) {
            let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
            let path = photoPath.appending("/\(sectionId)_profile.png")
            profileImageView.image = UIImage(contentsOfFile: path) ?? UIImage(named: "CourseBackground.jpg")!
        }
        
        profileImageView.contentMode = UIViewContentMode.scaleAspectFill
        profileImageView.clipsToBounds = true
        
        self.teacherName.text = self.classObject["teacherName"] as? String ?? ""
        self.roomNumber.text = self.classObject["roomNumber"] as? String ?? ""
        self.courseName.text = self.classObject["className"] as? String ?? ""
    }

    func refreshContent() {
        guard loginAuthentication().success else {
            return
        }
        
        DispatchQueue.main.async {
            self.configureBasicInfoView()
        }

        guard let sectionId = ClassView().getLeadSectionID(classDict: classObject) else {
            return
        }

        DispatchQueue.main.async {
            self.navigationController?.showProgress()
            self.navigationController?.setIndeterminate(true)
            SVProgressHUD.show()
            UIApplication.shared.isNetworkActivityIndicatorVisible = true
        }
        
        let sectionIdString = ClassView().getLeadSectionIDFromSectionInfo(sectionID: String(describing: sectionId))
        
        let semaphore = DispatchSemaphore(value: 0)

        provider.request(.getPossibleContent(sectionId: sectionIdString), completion: {
            (result) in
            switch result {
            case let .success(response):
                do {
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? Array<Dictionary<String, Any>> else {
                        presentErrorMessage(presentMessage: "Internal error: Incorrect data format", layout: .statusLine)
                        semaphore.signal()
                        return
                    }

                    self.availableInformation = []
                    var contentNameList = self.contentIDToName(inputData: json, sectionId: sectionIdString)

                    contentNameList.remove(object: "Photo")

                    self.availableInformation += contentNameList

                    for contentName in self.availableInformation {
                        self.sectionShouldShowMore[contentName] = false
                    }
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                }
            case let .failure(error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
            }

            semaphore.signal()
        })

        semaphore.wait()

        downloadContentData(sectionId: sectionIdString)

        DispatchQueue.main.async {
            self.classDetailTable.reloadData()
            self.navigationController?.cancelProgress()
            SVProgressHUD.dismiss()
            UIApplication.shared.isNetworkActivityIndicatorVisible = false
        }
    }

    func downloadContentData(sectionId: String) {
        let group = DispatchGroup()
        for contentName in self.availableInformation {
            guard contentName != "Basic" else {
                continue
            }
            
            // Bug fix
            let contentNameRemovedWhitespace = contentName.replacingOccurrences(of: " ", with: "")

            DispatchQueue.global().async(group: group, execute: {
                let semaphore = DispatchSemaphore(value: 0)
                provider.request(MyService.getClassContentData(contentName: contentNameRemovedWhitespace, sectionId: sectionId), completion: { result in
                    switch result {

                    case let .success(response):
                        print(response.request?.url)
                        do {
                            guard let json = try response.mapJSON(failsOnEmptyData: true) as? Array<Dictionary<String, Any?>> else {
                                semaphore.signal()
                                return
                            }

                            guard !json.isEmpty else {
                                self.availableInformation.remove(object: contentName)
                                semaphore.signal()
                                return
                            }
                            self.contentList[contentName] = json
                        } catch {
                            self.availableInformation.remove(object: contentName)
                            presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                        }
                    case let .failure(error):
                        presentErrorMessage(presentMessage: error.localizedDescription, layout: .statusLine)
                    }
                    semaphore.signal()
                })

                semaphore.wait()
            })
        }

        group.wait()
    }

    func contentIDToName(inputData: Array<Dictionary<String, Any?>>, sectionId: String) -> Array<String> {
        var contentNameList = [String]()
        guard let filePath = Bundle.main.url(forResource: "GroupPossibleContent", withExtension: "plist") else {
            presentErrorMessage(presentMessage: "Resource file missing.", layout: .statusLine)
            return []
        }

        guard let contentLUT = NSArray(contentsOf: filePath) as? Array<Dictionary<String, Any?>> else {
            presentErrorMessage(presentMessage: "Resource file has incorrect format", layout: .statusLine)
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
//    tableView delegate & dataSource
    override func numberOfSections(in tableView: UITableView) -> Int {
        return availableInformation.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch availableInformation[section] {
        case "Basic":
            return 1
        default:
            let sectionName = availableInformation[section]
            let contentCount = contentList[sectionName]?.count ?? 0
            if (sectionShouldShowMore[sectionName] ?? false) {
                return contentCount
            } else {
                return [2, contentCount].min()!
            }
        }
    }

    override func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if !shouldDisplayFooterViewAt(section: section) {
            return nil
        }

        let sectionName = availableInformation[section]

        let cell = tableView.dequeueReusableCell(withIdentifier: "classTableShowMoreFooter") as! classTableShowMoreFooter

        cell.sectionName = sectionName

        return cell
    }

    func shouldDisplayFooterViewAt(section: Int) -> Bool {
        let sectionName = availableInformation[section]

        if sectionShouldShowMore[sectionName] ?? true {
            return false
        } else if (contentList[sectionName]?.count ?? 0) < 3 {
            return false
        } else {
            return true
        }
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if availableInformation[indexPath.section] == "Basic" {
            return 170
        }

        return UITableViewAutomaticDimension
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: "homeworkTableHeader") as! homeworkTableHeader

        let headerText = availableInformation[section]

        if overrideHeader[headerText] != nil {
            headerView.titleLabel.text = overrideHeader[headerText]
        } else {
            headerView.titleLabel.text = headerText
        }

        return headerView
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch availableInformation[section] {
        case "Basic":
            return 0
        default:
            return 46
        }
    }

    override func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if shouldDisplayFooterViewAt(section: section) {
            return 86
        } else {
            return 40
        }
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let section = indexPath.section

        switch availableInformation[section] {
        case "Basic":
            let cell = classDetailTable.dequeueReusableCell(withIdentifier: "classOverviewTable", for: indexPath)
            let sectionId = ClassView().getLeadSectionID(classDict: classObject) ?? 0
            let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
            let path = photoPath.appending("/\(sectionId)_profile.png")
            profileImageView.image = UIImage(contentsOfFile: path) ?? UIImage(named: "CourseBackground.jpg")!
            profileImageView.contentMode = UIViewContentMode.scaleAspectFill
            profileImageView.clipsToBounds = true

            cell.selectionStyle = .none

            basicInformationView.frame = CGRect(x: 0, y: 0, width: cell.frame.size.width, height: cell.frame.size.height)
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
        case "Expectation", "Grading Rubric":
            var cell = tableView.dequeueReusableCell(withIdentifier: "syllabusCell", for: indexPath) as! syllabusView

            handleCellData(cell: &cell, buttonTitleKey: "ShortDescription", textViewTextKey: "Description", indexPath: indexPath)

            return cell
        default:
            break
        }

        return UITableViewCell()
    }

    func handleCellData(cell: inout syllabusView, buttonTitleKey: String, textViewTextKey: String, indexPath: IndexPath) {
        let sectionName = availableInformation[indexPath.section]
        guard let dictData = contentList[sectionName]?[indexPath.row] else {
            return
        }

        cell.attachmentQueryString = dictData["AttachmentQueryString"] as? String
        var attachmentFileName: String? {
            if dictData["Attachment"] is String {
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
        
        if ((!cell.url.existsAndNotEmpty() && !cell.attachmentFileName.existsAndNotEmpty())) || cell.title.currentTitle!.isEmpty {
            cell.title.isEnabled = false
        } else {
            cell.title.isEnabled = true
        }

        cell.selectionStyle = .none
    }
}

extension classDetailViewController {

    func getProfilePhoto(photoLink: String, sectionId: String) {
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
                    presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
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
                guard let json = try! JSON(data: data!).arrayObject as? [NSDictionary] else {
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
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
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
    var heightConstraint: Constraint? = nil
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
            self.heightConstraint?.deactivate()
            self.syllabusDescription.sizeToFit()
            self.showMoreView.isHidden = true
            self.layoutIfNeeded()
            thisParentViewController?.tableView.endUpdates()
        }
    }


    @IBAction func titleClicked(_ sender: Any) {
        DispatchQueue.global().async {
            self.openContent()
        }
    }
    
    func openContent() {
        DispatchQueue.main.async {
            self.parentViewController!.navigationController?.showProgress()
            SVProgressHUD.show()
            self.parentViewController!.navigationController?.setIndeterminate(true)
        }
        
        if self.url != nil {
            NetworkOperations().openLink(url: &self.url!, from: parentViewController!)
            DispatchQueue.main.async {
                self.parentViewController!.navigationController?.cancelProgress()
                SVProgressHUD.dismiss()
            }
            return
        }
        
        guard !self.attachmentFileName!.isEmpty else {
            presentErrorMessage(presentMessage: "There is no attachment.", layout: .cardView)
            DispatchQueue.main.async {
                self.parentViewController!.navigationController?.cancelProgress()
                SVProgressHUD.dismiss()
            }
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
            NetworkOperations().openFile(fileUrl:  URL(fileURLWithPath: attachmentPath), from: parentViewController!)
            DispatchQueue.main.async {
                self.parentViewController!.navigationController?.cancelProgress()
                SVProgressHUD.dismiss()
            }
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
        
        let (filePath, error) = NetworkOperations().downloadFile(url: URL(string: url)!, withName: attachmentFileName!)
        
        DispatchQueue.main.async {
            self.parentViewController!.navigationController?.cancelProgress()
            SVProgressHUD.dismiss()
        }
        
        guard error == nil else {
            presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
            return
        }
        
        if filePath != nil {
            NetworkOperations().openFile(fileUrl: filePath!, from: parentViewController!)
        }
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

class classTableShowMoreFooter: UITableViewCell {
    var sectionName: String? = nil

    @IBAction func showMoreButtonClicked(_ sender: Any) {
        guard sectionName != nil else {
            return
        }

        guard let parentViewControllerInstance = parentViewController as? classDetailViewController else {
            return
        }

        parentViewControllerInstance.sectionShouldShowMore[sectionName!] = true
        parentViewControllerInstance.tableView.reloadData()
    }
}
