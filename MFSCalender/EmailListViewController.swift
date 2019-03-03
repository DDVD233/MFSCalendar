//
//  EmailListViewController.swift
//  MFSMobile
//
//  Created by David Dai on 3/2/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import SwiftDate

class EmailListViewController: UIViewController {
    var emailList = [[String: Any]]()
    // Structure: Array {
    //              Dict {
    //                        title: titleString
    //                        data: Array { Email }
    //              }
    //            }
    @IBOutlet var emailTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.emailTable.dataSource = self
        self.emailTable.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getAllEmails()
    }
    
    func getAllEmails() {
        emailList = [[String: Any]]()
        let emailName = Preferences().emailName
        let emailPassword = Preferences().emailPassword
        provider.request(MyService.getAllEmails(username: emailName!, password: emailPassword!)) { (result) in
            switch result {
            case .success(let response):
                do {
                    guard self.viewIfLoaded?.window != nil else {
                        return
                    }
                    
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? [[String: Any]] else {
                        return
                    }
                    
                    for items in json {
                        let email = Email(senderName: items["senderName"] as? String ?? "",
                                          senderAddress: items["senderAddress"] as? String ?? "",
                                          body: items["body"] as? String ?? "",
                                          subject: items["subject"] as? String ?? "",
                                          timeStamp: items["timestamp"] as? Int ?? 0)
                        let receivedDate = DateInRegion.init(seconds: TimeInterval(email.timeStamp))
                        let now = DateInRegion()
                        var title = ""
                        if receivedDate.isAfterDate(now.dateAtStartOf(.day), granularity: .second) {
                            title = "Today"
                        } else if receivedDate.isAfterDate((now - 1.days).dateAtStartOf(.day), granularity: .second) {
                            title = "Yesterday"
                        } else if receivedDate.isAfterDate(now.dateAt(.startOfWeek), granularity: .second) {
                            title = "This Week"
                        }
                        
                        if let arrayIndex = self.emailList.firstIndex(where: { (dict) -> Bool in
                            return dict["title"] as? String == title
                        }) {
                            var arrayForTitle = self.emailList[arrayIndex]
                            var dataList = arrayForTitle["data"] as? [Email] ?? [Email]()
                            dataList.append(email)
                            arrayForTitle["data"] = dataList
                            self.emailList[arrayIndex] = arrayForTitle
                        } else {
                            let arrayToAdd = ["title": title, "data": [email]] as [String : Any]
                            self.emailList.append(arrayToAdd)
                        }
                    }
                    
                    self.emailTable.reloadData()
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
                }
            case .failure(let error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
            }
        }
    }
}

extension EmailListViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 44
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return emailList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return emailList[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "emailListCell", for: indexPath) as! EmailListCell
        guard let emailListInSection = emailList[indexPath.section]["data"] as? [Email] else {
            return cell
        }
        guard let emailObject = emailListInSection[safe: indexPath.row] else {
            return cell
        }
        cell.subject.text = emailObject.subject
        cell.senderName.text = emailObject.senderName
        cell.body.text = emailObject.body
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueReusableCell(withIdentifier: "emailTableHeader") as! EmailTableHeader
        headerView.titleLabel.text = emailList[section]["title"] as? String ?? ""
        return headerView
    }
}

class EmailListCell: UITableViewCell {
    
    @IBOutlet var senderName: UILabel!
    @IBOutlet var subject: UILabel!
    @IBOutlet var body: UITextView!
    @IBOutlet var unreadIndicator: UIView!
}

class EmailTableHeader: UITableViewCell {
    @IBOutlet var titleLabel: UILabel!
}
