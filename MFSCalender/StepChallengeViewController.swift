//
//  StepChallengeViewController.swift
//  MFSMobile
//
//  Created by 戴元平 on 11/20/18.
//  Copyright © 2018 David. All rights reserved.
//

import UIKit
import SDWebImage

class StepChallengeViewController: UIViewController {
    var stepArray = [[String: Any]]()
    @IBOutlet var stepTable: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.stepTable.delegate = self
        self.stepTable.dataSource = self
        StepChallenge().reportSteps()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
        
        getSteps()
    }
    
    func getSteps() {
        let date = Date()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd"
        let checkDate = formatter.string(from: date)
        
        provider.request(MyService.getSteps(date: checkDate), callbackQueue: DispatchQueue.global()) { (result) in
            switch result {
            case .success(let response):
                do {
                    guard let json = try JSONSerialization.jsonObject(with: response.data, options: .allowFragments) as? [[String: Any]] else {
                        print("Failed to construct json object.")
                        return
                    }
                    
                    self.stepArray = json
                    print(json)
                    self.sortSteps()
                } catch {
                    print(error.localizedDescription)
                }
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func sortSteps() {
        stepArray = stepArray.sorted(by: { (first, second) -> Bool in
            let firstStep = Int(first["steps"] as? String ?? "0") ?? 0
            let secondStep = Int(second["steps"] as? String ?? "0") ?? 0
            return  firstStep<secondStep
        })
        
        DispatchQueue.main.async {
            self.stepTable.reloadData()
        }
    }
}

extension StepChallengeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return stepArray.count;
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let stepRecord = stepArray[indexPath.row]
        let cell = stepTable.dequeueReusableCell(withIdentifier: "stepRecord", for: indexPath) as! StepTableCell
        
        cell.name.text = stepRecord["name"] as? String ?? ""
        cell.rank.text = String(indexPath.row + 1)
        cell.steps.text = String(stepRecord["steps"] as? Int ?? 0)
        let photoLink = stepRecord["link"] as? String ?? ""
        let photoURL = URL(string: "https://mfriends.myschoolapp.com" + photoLink)
        cell.photo.sd_setImage(with: photoURL, completed: nil)
        cell.photo.contentMode = .scaleAspectFill
        return cell
    }
    
    
}

class StepChallenge {
    func reportSteps() {
        let steps = "260"
        let preferences = Preferences()
        let username = (preferences.firstName ?? "") + " " + (preferences.lastName ?? "")
        let link = (preferences.photoLink ?? "none")
        provider.request(MyService.reportSteps(steps: steps, username: username, link: link)) { (result) in
            switch result {
            case .success(let response):
                print("Successfully uploaded the result")
                break
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
}

class StepTableCell: UITableViewCell {
    @IBOutlet var rank: UILabel!
    @IBOutlet var photo: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var steps: UILabel!
}
