//
//  HomeworkDetailViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/9/8.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import M13Checkbox

class homeworKDetailViewController: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    var contentList = [[String: Any]]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        getTheHomeworkToPresent()
    }
    
    func getTheHomeworkToPresent() {
        guard let assignmentIndexID = userDefaults?.integer(forKey: "indexIdForAssignmentToPresent") else {
            return
        }
        
        let (success, _, userId) = loginAuthentication()
        
        guard success else {
            return
        }
        
        let url = URL(string: "https://mfriends.myschoolapp.com/api/datadirect/AssignmentStudentDetail?format=json&studentId=\(userId)&AssignmentIndexId=\(assignmentIndexID)")!
        let semaphore = DispatchSemaphore(value: 0)
        
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard error == nil else {
                presentErrorMessage(presentMessage: error!.localizedDescription, layout: .CardView)
                semaphore.signal()
                return
            }
            do {
                if let json = try JSONSerialization.jsonObject(with: data!, options: .allowFragments) as? [[String: Any]] {
                   // print(json)
                    self.contentList = json
                }
            } catch {
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .CardView)
            }
            
            semaphore.signal()
        })
        
        task.resume()
        semaphore.wait()
        
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }
    
    func loadContents(dict: [String: Any]) {
        
    }
}

extension homeworKDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "homeworkDetailViewCell", for: indexPath) as! homeworkDetailViewCell
        let contentObject = contentList[indexPath.row]
        
        if let assignmentIndexID = userDefaults?.integer(forKey: "indexIdForAssignmentToPresent") {
            cell.assignmentIndexID = String(describing: assignmentIndexID)
        }
        
        
        if let shortDescription = contentObject["title"] as? String {
            cell.title.text = shortDescription.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression, range: nil)
        }
        if let longDescription = contentObject["description"] as? String {
            if let attributedText = longDescription.convertToHtml() {
                cell.textView.attributedText = attributedText
            }
        }
        
        if let assigmentStatus = contentObject["assignmentStatus"] as? Int {
            let checkState = HomeworkView().checkStateFor(status: assigmentStatus)
            cell.checkBox.setCheckState(checkState, animated: true)
        }
        
        let assignmentType = contentObject["assignmentType"] as? String ?? ""
        cell.checkBox.tintColor = HomeworkView().colorForTheType(type: assignmentType)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 200
    }
}

class homeworkDetailViewCell: UITableViewCell {
    @IBOutlet var title: UILabel!
    @IBOutlet var textView: UITextView!
    @IBOutlet var checkBox: M13Checkbox!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    var assignmentIndexID: String? = nil
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        textView.isEditable = false
        activityIndicator.isHidden = true
        checkBox.stateChangeAnimation = .bounce(.fill)
        checkBox.boxLineWidth = 3
        checkBox.addTarget(self, action: #selector(checkDidChange), for: UIControlEvents.valueChanged)
    }
    
    func checkDidChange() {
        DispatchQueue.global().async {
            guard (self.assignmentIndexID != nil) else {
                return
            }
            
            var assignmentStatus: String? = nil
            switch self.checkBox.checkState {
            case .checked:
                assignmentStatus = "1"
            case .unchecked:
                assignmentStatus = "-1"
            default:
                NSLog("Something strange happened.")
                return
            }
            
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = false
                self.activityIndicator.startAnimating()
            }
            
            do {
                try HomeworkView().updateAssignmentStatus(assignmentIndexId: self.assignmentIndexID!, assignmentStatus: assignmentStatus!)
            } catch {
                switch self.checkBox.checkState {
                case .checked:
                    self.checkBox.setCheckState(.unchecked, animated: false)
                case .unchecked:
                    self.checkBox.setCheckState(.checked, animated: false)
                default:
                    break
                }
            }
            
            DispatchQueue.main.async {
                self.activityIndicator.isHidden = true
                self.activityIndicator.stopAnimating()
            }
        }
    }
}


