//
//  ProfileViewController.swift
//  MFSCalendar
//
//  Created by 戴元平 on 2017/8/30.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import Down
import MessageUI

class aboutView: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet var dependenciesTextView: UITextView!
    @IBOutlet var buildVersion: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let buildVersionText = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""
        let versionText = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        buildVersion.text = "Version " + versionText + " (" + buildVersionText + ")"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let podAckFile = Bundle.main.url(forResource: "Acknowledgements", withExtension: "markdown")!
        let down = Down(markdownString: try! String(contentsOf: podAckFile))
        tableView.estimatedRowHeight = 50
        
        if let attributedString = try? down.toAttributedString() {
            dependenciesTextView.attributedText = attributedString
            dependenciesTextView.isScrollEnabled = false
            dependenciesTextView.sizeToFit()
            tableView.reloadData()
        }
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 2 {
            return UITableViewAutomaticDimension
        } else {
            return 44
        }
    }
    
    @IBAction func sendEmail(_ sender: Any) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail() {
            self.present(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    @IBAction func openGithub(_ sender: Any) {
        UIApplication.shared.openURL(URL(string: "https://github.com/zjdavid/MFSCalendar")!)
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self // Extremely important to set the --mailComposeDelegate-- property, NOT the --delegate-- property
        
        mailComposerVC.setToRecipients(["zjdavid.2003@gmail.com", "daiw@mfriends.org"])
        mailComposerVC.setSubject("Bug reports and suggestions")
        mailComposerVC.setMessageBody("", isHTML: false)
        
        return mailComposerVC
    }
    
    func showSendMailErrorAlert() {
        let sendMailErrorAlert = UIAlertController(title: "Could Not Send Email", message: "Your device could not send e-mail.  Please check e-mail configuration and try again.", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
        sendMailErrorAlert.addAction(okAction)
        self.present(sendMailErrorAlert, animated: true, completion: nil)
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}
