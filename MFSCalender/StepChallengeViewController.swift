//
//  StepChallengeViewController.swift
//  MFSMobile
//
//  Created by 戴元平 on 11/20/18.
//  Copyright © 2018 David. All rights reserved.
//

import UIKit
import SDWebImage
import HealthKit

class StepChallengeViewController: UIViewController {
    var stepArray = [[String: Any]]()
    @IBOutlet var stepTable: UITableView!
    let stepChallenge = StepChallenge()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.stepTable.delegate = self
        self.stepTable.dataSource = self
        stepChallenge.reportSteps()
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
    let healthManager: HealthKitManager = HealthKitManager()
    let healthStore = HKHealthStore()
    
    func getTodaysSteps(completion: @escaping (Double) -> Void) {
        let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let result = result, let sum = result.sumQuantity() else {
                completion(0.0)
                return
            }
            completion(sum.doubleValue(for: HKUnit.count()))
        }
        
        healthStore.execute(query)
    }
    
    func uploadResult(steps: String) {
        let preferences = Preferences()
        let username = (preferences.firstName ?? "") + " " + (preferences.lastName ?? "")
        let link = (preferences.photoLink ?? "none")
        provider.request(MyService.reportSteps(steps: steps, username: username, link: link)) { (result) in
            switch result {
            case .success(let _):
                print("Successfully uploaded the result")
                break
            case .failure(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    func reportSteps() {
        // 在 HealthKitManager.swift 文件里寻找授权情况。
        healthManager.authorizeHealthKit { (authorized,  error) -> Void in
            if authorized {
                // Great!
                self.getTodaysSteps { (steps) in
                    let stepsString = String(Int(steps))
                    self.uploadResult(steps: stepsString)
                }
            } else {
                if error != nil {
                    print(error as Any)
                }
                print("Permission denied.")
            }
        }
    }
}

class HealthKitManager {
    let healthKitStore: HKHealthStore = HKHealthStore()
    
    func authorizeHealthKit(completion: @escaping (_ success: Bool, _ error: Error?) -> Void) {
        
        // 声明我们想从 HealthKit 里读取的健康数据的类型
        let healthDataToRead = Set(arrayLiteral: HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)!)
        
        if !HKHealthStore.isHealthDataAvailable() {
            print("Can't access HealthKit.")
        }
        
        // 请求可以读取数据的权限
        healthKitStore.requestAuthorization(toShare: nil, read: healthDataToRead) { (success, error) -> Void in
                completion(success, error)
        }
    }
}

class StepTableCell: UITableViewCell {
    @IBOutlet var rank: UILabel!
    @IBOutlet var photo: UIImageView!
    @IBOutlet var name: UILabel!
    @IBOutlet var steps: UILabel!
}
