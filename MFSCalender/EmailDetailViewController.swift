//
//  EmailDetailViewController.swift
//  MFSMobile
//                                                       
//  Created by David Dai on 3/5/19.
//  Copyright © 2019 David. All rights reserved.
//

import UIKit
import WebKit
import Down
import SnapKit

class EmailDetailViewController: UIViewController, WKUIDelegate {
    @IBOutlet var emailDetailTable: UITableView!
    var emailToDisplay: Email? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        emailDetailTable.delegate = self
        emailDetailTable.dataSource = self
        let idToDisplay = Preferences().emailIDToDisplay ?? ""
        
        getEmailWithId(id: idToDisplay)
    }
    
    func getEmailWithId(id: String) {
        let pref = Preferences()
        provider.request(MyService.getEmailWithID(username: pref.emailName ?? "", password: pref.emailPassword ?? "", id: id)) { (result) in
            switch result {
            case .success(let response):
                do {
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? [String: Any] else {
                        return
                    }
                    self.emailToDisplay = Email(dict: json)
                    print(self.emailToDisplay?.subject)
                    self.emailDetailTable.reloadData()
                } catch {
                    presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
                }
            case .failure(let error):
                presentErrorMessage(presentMessage: error.localizedDescription, layout: .cardView)
            }
        }
    }
}

extension EmailDetailViewController: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        if emailToDisplay == nil {
            return 0
        }
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0 {
            return 50
        } else {
            return 200
        }
//        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
//        if indexPath.row == 0 {
//            return 50
//        } else {
//            return 200
//        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let emailObject = emailToDisplay else {
            return UITableViewCell()
        }
        switch indexPath.row {
        case 1:
            let cell = emailDetailTable.dequeueReusableCell(withIdentifier: "emailDetailBodyCell", for: indexPath) as! EmailDetailBodyCell
            let webConfiguration = WKWebViewConfiguration()
            cell.webView = WKWebView(frame: .zero, configuration: webConfiguration)
            
            cell.webView.uiDelegate = self
            
            let bodyText = "<meta name=\"viewport\" content=\"initial-scale=1.0\" />" + emailObject.body
            cell.webView.loadHTMLString(bodyText, baseURL: Bundle.main.bundleURL)
            
            cell.webView.scrollView.isScrollEnabled = false
            cell.webView.sizeToFit()
            cell.addSubview(cell.webView)
            cell.webView.snp.makeConstraints { (make) in
                make.bottom.equalToSuperview()
                make.top.equalToSuperview()
                make.leadingMargin.equalToSuperview()
                make.trailingMargin.equalToSuperview()
            }
            
            cell.layoutIfNeeded()
            
            return cell
        case 0:
            let cell = emailDetailTable.dequeueReusableCell(withIdentifier: "emailHeaderCell", for: indexPath) as! EmailHeaderCell
            cell.headerLabel.text = emailObject.subject
            
            return cell
        default:
            return UITableViewCell()
        }
    }
    
    
}

class EmailDetailBodyCell: UITableViewCell, WKNavigationDelegate {
    var webView: WKWebView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        webView.navigationDelegate = self
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.webView.evaluateJavaScript("document.readyState", completionHandler: { (complete, error) in
            if complete != nil {
                self.webView.evaluateJavaScript("document.body.scrollHeight", completionHandler: { (height, error) in
                    self.webView.snp.makeConstraints({ (make) in
                        make.height.equalTo(height as! CGFloat)
                    })
                    
                    let parent = self.parentViewController as! EmailDetailViewController
                    parent.emailDetailTable.beginUpdates()
                    self.layoutIfNeeded()
                    parent.emailDetailTable.endUpdates()
                })
            }
        })
        
    }
}

class EmailHeaderCell: UITableViewCell {
    @IBOutlet var headerLabel: UILabel!
}
