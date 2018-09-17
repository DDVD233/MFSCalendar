//
//  TopicDetailViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/8/8.
//  Copyright © 2017 David. All rights reserved.
//

import UIKit
import SafariServices
import Alamofire
import SVProgressHUD

class topicDetailViewController: UIViewController {
    let topicID = Preferences().topicID
    let topicIndexID = Preferences().topicIndexID

    var topicData = [[String: Any]]()

    @IBOutlet var topicDetailTable: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()

        topicDetailTable.rowHeight = UITableView.automaticDimension
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


        let rowNumber = topicData.filter({ $0["CellIndex"] as? Int == section }).count

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
    
    func topicObjectForCell(at indexPath: IndexPath) -> [String: Any]? {
        var topicObject:[String: Any]? = nil
        
        let topicObjectOfTheSection = topicData.filter({
            $0["CellIndex"] as? Int == indexPath.section
        })
        
        //        In some rare cases, the sort order start with 1 and the first cell is missing.
        if let thisTopicObject = topicObjectOfTheSection.filter({ $0["SortOrder"] as? Int == indexPath.row }).first {
            topicObject = thisTopicObject
        } else if topicObjectOfTheSection.indices.contains(indexPath.row) {
            topicObject = topicObjectOfTheSection[indexPath.row]
        }
        
        return topicObject
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "topicCell", for: indexPath) as! topicDetailDescriptionCell

        guard let topicObject = topicObjectForCell(at: indexPath) else {
            NSLog("Cell data not found")
            return UITableViewCell()
        }

        cell.selectionStyle = .default

        if let longDescription = topicObject["LongDescription"] as? String {
            if !longDescription.isEmpty {
                if let htmlString = longDescription.convertToHtml() {
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

        let shortDescription = topicObject["ShortDescription"] as? String ?? ""
        cell.title.text = shortDescription

        cell.imageView?.image = nil

        if topicObject["Url"] != nil {
            cell.linkImage.image = UIImage(named: "Link")
        } else if (topicObject["filePath"] as? String).existsAndNotEmpty() && topicObject["fileName"] != nil {
            cell.linkImage.image = UIImage(named: "Download")
        } else {
            cell.linkImage.image = nil
        }

        cell.linkImage.contentMode = .scaleToFill

        if cell.longDescription.text.isEmpty && cell.title.text!.isEmpty {
            cell.isHidden = true
        }

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard let topicObject = topicObjectForCell(at: indexPath) else {
            return
        }
        
        var url = topicObject["Url"] as? String
        var filePath: String? = nil
        if let topicFilePath = topicObject["FilePath"] as? String {
            filePath = "https://mfriends.myschoolapp.com" + topicFilePath
        }
        
        let fileName = topicObject["FileName"] as? String
        
        if url != nil {
            NetworkOperations().openLink(url: &url!, from: self)
        } else if filePath != nil && fileName != nil {
            DispatchQueue.main.async {
                self.navigationController?.showProgress()
                self.navigationController?.setIndeterminate(true)
                SVProgressHUD.show()
            }
            
            let path = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
            let attachmentPath = path.appending("/" + fileName!)
            NSLog("AttachmentPath: \(attachmentPath)")
            //Init FileManager
            let fileManager = FileManager.default
            if fileManager.fileExists(atPath: attachmentPath) {
                //          Open the existing attachment.
                NSLog("Attempting to open file: \(fileName!)")
                DispatchQueue.main.async {
                    self.navigationController?.cancelProgress()
                    SVProgressHUD.dismiss()
                }
                
                NetworkOperations().openFile(fileUrl: URL(fileURLWithPath: attachmentPath), from: self)
                return
            }
            
            guard loginAuthentication().success else {
                return
            }
            
            let url = filePath! + fileName!
            
            let (fileURL, error) = NetworkOperations().downloadFile(url: URL(string: url)!, withName: fileName!)
            DispatchQueue.main.async {
                self.navigationController?.cancelProgress()
                SVProgressHUD.dismiss()
            }
            
            guard error == nil else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .cardView)
                return
            }
            
            if fileURL != nil {
                NetworkOperations().openFile(fileUrl: fileURL!, from: self)
            }
        }
    }
}

extension topicDetailViewController {
//    Network
    func getTopicDetailData() {

        DispatchQueue.main.async {
            self.navigationController?.showProgress()
            self.navigationController?.setIndeterminate(true)
            SVProgressHUD.show()
        }

        guard loginAuthentication().success else {
            NSLog("Login failed")
            return
        }

        let topicIDString = String(describing: topicID)
        let topicIndexIDString = String(describing: topicIndexID)

        let url = "https://mfriends.myschoolapp.com/api/datadirect/topiccontentget/\(topicIDString)/?format=json&index_id=\(topicIndexIDString)&id=\(topicIndexIDString)"
        let semaphore = DispatchSemaphore.init(value: 0)

        let dataTask = URLSession.shared.dataTask(with: URL(string: url)!, completionHandler: { (data, response, error) in
            guard error == nil else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .statusLine)
                semaphore.signal()
                return
            }

            do {
                guard var json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? Array<Dictionary<String, Any>> else {
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
            SVProgressHUD.dismiss()
        }
    }

    func flattenColumn(data: inout Array<Dictionary<String, Any>>) {
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
    @IBOutlet var title: UILabel!
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
        DispatchQueue.global().async {
            self.openContent()
        }
    }
    
    func openContent() {
        
    }
}
