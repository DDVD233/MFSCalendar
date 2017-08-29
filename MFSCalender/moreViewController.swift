//
//  moreViewController.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/4/23.
//  Copyright © 2017年 David. All rights reserved.
//

import UIKit
import UserNotifications
import MessageUI
import SafariServices
import Down

class moreViewController: UITableViewController {

    @IBOutlet weak var profilePhoto: UIImageView!
    @IBOutlet weak var name: UILabel!

    @IBOutlet weak var settingImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        let photoPath = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!.path
        let path = photoPath.appending("/ProfilePhoto.png")
        profilePhoto.image = UIImage(contentsOfFile: path)
        profilePhoto.contentMode = UIViewContentMode.scaleAspectFill

        name.text = ""
        if let firstName = userDefaults?.string(forKey: "firstName") {
            name.text?.append(firstName + " ")
        }

        if let lastName = userDefaults?.string(forKey: "lastName") {
            name.text?.append(lastName)
        }
    }

}

extension moreViewController {
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 1 && indexPath.row == 2 {
            let url = URL(string: "https://mfriends.myschoolapp.com/app/student#resourceboard")!
            let safariPage = SFSafariViewController(url: url)
            self.present(safariPage, animated: true, completion: nil)
        }
    }
}


class profileViewController: UITableViewController {
    @IBOutlet weak var firstName: UILabel!
    @IBOutlet weak var lastName: UILabel!
    @IBOutlet weak var lockerNumber: UILabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        firstName.text = userDefaults?.string(forKey: "firstName")
        lastName.text = userDefaults?.string(forKey: "lastName")
        lockerNumber.text = userDefaults?.string(forKey: "lockerNumber")
    }


}


class aboutView: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet var dependenciesTextView: UITextView!

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
