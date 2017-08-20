//
//  TopicDetailViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/8/8.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import SafariServices
import Alamofire

class topicDetailViewController: UIViewController {
    let topicID = userDefaults?.integer(forKey: "topicID")
    let topicIndexID = userDefaults?.integer(forKey: "topicIndexID")
    
    var topicData = [[String: Any?]]()
    
    @IBOutlet var topicDetailTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topicDetailTable.rowHeight = UITableViewAutomaticDimension
        topicDetailTable.estimatedRowHeight = 50
        topicDetailTable.delegate = self
        topicDetailTable.dataSource = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        DispatchQueue.global().async {
            self.getTopicDetailData()
        }
    }
}

extension topicDetailViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        guard let topicObject = topicData.filter({
            $0["CellIndex"] as? Int == section
        }).first else {
            return nil
        }
        
        return topicObject["SubCategory"] as? String
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        
        let rowNumber = topicData.filter({ $0["CellIndex"] as? Int == section}).count
        
        return rowNumber
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        guard let lastObject = topicData.last else {
            return 0
        }
        
        guard let endIndex = lastObject["CellIndex"] as? Int else {
            return 0
        }
        
        // Note that index begins with 0
        return endIndex + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "topicCell", for: indexPath) as! topicDetailDescriptionCell
        let topicObjectOfTheSection = topicData.filter({
            $0["CellIndex"] as? Int == indexPath.section
        })
        
        var topicObject = [String: Any?]()
        
//        In some rare cases, the sort order start with 1 and the first cell is missing.
        if let thisTopicObject = topicObjectOfTheSection.filter({ $0["SortOrder"] as? Int == indexPath.row }).first {
            topicObject = thisTopicObject
        } else if topicObjectOfTheSection.indices.contains(indexPath.row) {
            topicObject = topicObjectOfTheSection[indexPath.row]
        }
        
        guard !topicObject.isEmpty else {
            NSLog("Cell data not found")
            return UITableViewCell()
        }
        
        cell.selectionStyle = .none
        
        if let longDescription = topicObject["LongDescription"] as? String {
            if !longDescription.isEmpty {
                if let htmlString = stringToHtml(string: longDescription) {
                    cell.longDescription.attributedText = htmlString
                    cell.longDescription.sizeToFit()
                    cell.longDescription.isScrollEnabled = false
                } else {
                    cell.longDescription.text = longDescription
                }
            }
        } else {
            cell.longDescription.text = ""
        }
        
        if let shortDescription = topicObject["ShortDescription"] as? String {
            cell.link.setTitle(shortDescription, for: .normal)
        } else {
            cell.link.setTitle("", for: .normal)
        }
        
        cell.imageView?.image = nil
        
        if let url = topicObject["Url"] as? String {
            cell.url = url
            cell.imageView?.image = UIImage(named: "Link")
        }
        
        if let filePath = topicObject["FilePath"] as? String, let fileName = topicObject["FileName"] as? String {
            cell.filePath = "https://mfriends.myschoolapp.com" + filePath
            cell.fileName = fileName
            cell.imageView?.image = UIImage(named: "Download")
        }
        
        cell.imageView?.contentMode = .scaleToFill
        
        if cell.longDescription.text.isEmpty && (cell.link.titleLabel?.text ?? "").isEmpty {
            cell.isHidden = true
        }
        
        return cell
    }
    
    func stringToHtml(string: String) -> NSAttributedString? {
        
        let htmlString = "<html>" +
            "<head>" +
            "<style>" +
            "body {" +
            "font-family: 'Helvetica';" +
            "font-size:15px;" +
            "text-decoration:none;" +
            "}" +
            "</style>" +
            "</head>" +
            "<body>" +
            string +
        "</body></head></html>"
        
        if let data = htmlString.data(using: .utf8, allowLossyConversion: true) {
            if let formattedHtmlString = try? NSAttributedString(data: data, options: [NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType], documentAttributes: nil) {
                return formattedHtmlString
            }
        }
        
        return nil
    }
}

extension topicDetailViewController {
//    Network
    func getTopicDetailData() {
        guard topicID != nil else {
            NSLog("TopicID not found!")
            return
        }
        
        guard topicIndexID != nil else {
            NSLog("Topic index ID not found!")
            return
        }
        
        DispatchQueue.main.async {
            self.navigationController?.showProgress()
            self.navigationController?.setIndeterminate(true)
        }
        
        guard loginAuthentication().success else {
            NSLog("Login failed")
            return
        }
        
        let topicIDString = String(describing: topicID!)
        let topicIndexIDString = String(describing: topicIndexID!)
        
        let url = "https://mfriends.myschoolapp.com/api/datadirect/topiccontentget/\(topicIDString)/?format=json&index_id=\(topicIndexIDString)&id=\(topicIndexIDString)"
        let semaphore = DispatchSemaphore.init(value: 0)
        
        let dataTask = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { (data, response, error) in
            guard error == nil else {
                presentErrorMessage(presentMessage: error!.localizedDescription)
                semaphore.signal()
                return
            }
            
            do {
                guard var json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Array<Dictionary<String, Any?>> else {
                    NSLog("Json file has incorrect format")
                    return
                }
                
                self.flattenColumn(data: &json)
                
                self.topicData = json
            } catch {
                NSLog("Json error: \(error.localizedDescription)")
            }
            
            semaphore.signal()
        })
        
        dataTask.resume()
        semaphore.wait()
        
        DispatchQueue.main.async {
            self.topicDetailTable.reloadData()
            self.navigationController?.cancelProgress()
        }
    }
    
    func flattenColumn(data: inout Array<Dictionary<String, Any?>>) {
        var previousSectionIndex = -1
        var previousCellIndex = 0
        
        for (index, items) in data.enumerated() {
            var thisTopic = items
            
            guard let thisSectionIndex = items["CellIndex"] as? Int else {
                NSLog("Index not found. 566")
                continue
            }
            
            let thisCellIndex = items["SortOrder"] as! Int
            
            if thisSectionIndex <= previousSectionIndex {
                
                if thisCellIndex <= previousCellIndex {
                    thisTopic["CellIndex"] = previousSectionIndex + 1
                } else {
                    thisTopic["CellIndex"] = previousSectionIndex
                }
                
                data[index] = thisTopic
            }
            
            previousSectionIndex = thisTopic["CellIndex"] as! Int
            previousCellIndex = thisCellIndex
        }
    }
}

extension topicDetailViewController: UIDocumentInteractionControllerDelegate {
    func documentInteractionControllerViewControllerForPreview(_ controller: UIDocumentInteractionController) -> UIViewController {
        return self
    }
}

class topicDetailDescriptionCell: UITableViewCell {
    @IBOutlet var link: UIButton!
    @IBOutlet var longDescription: UITextView!
    
    @IBOutlet var linkImage: UIImageView!
    
    
    var url: String? = nil
    var filePath: String? = nil
    var fileName: String? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        longDescription.isEditable = false
    }
    
    @IBAction func linkButtonClicked(_ sender: Any) {
        if url != nil {
            let safariController = SFSafariViewController(url: URL(string: url!)!)
            if let rootViewController = self.parentViewController?.navigationController {
                rootViewController.present(safariController, animated: true, completion: nil)
            }
        } else if filePath != nil && fileName != nil {
            
            DispatchQueue.main.async {
                self.parentViewController!.navigationController?.showProgress()
                self.parentViewController!.navigationController?.setIndeterminate(true)
            }
            
            let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
            let attachmentPath = path.appending("/" + fileName!)
            NSLog("AttachmentPath: \(attachmentPath)")
            //Init FileManager
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: attachmentPath) {
                //          Open the existing attachment.
                NSLog("Attempting to open file: \(fileName!)")
                openFile(fileUrl: URL(fileURLWithPath: attachmentPath))
                return
            }
            
            guard loginAuthentication().success else {
                return
            }
            
            let url = filePath! + fileName!
            //        create request.
            //        Alamofire Test.
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                let fileURL = URL(fileURLWithPath: attachmentPath)
                print(fileURL)
                
                return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
            }
            
            
            Alamofire.download(url, to: destination).response { response in
                
                if response.error == nil {
                    
                    NSLog("Attempting to open file: \(self.fileName!)")
                    self.openFile(fileUrl: URL(fileURLWithPath: attachmentPath))
                } else {
                    DispatchQueue.main.async {
                        self.parentViewController!.navigationController?.cancelProgress()
                        let message = response.error!.localizedDescription + " Please check your internet connection."
                        presentErrorMessage(presentMessage: message)
                    }
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
}
