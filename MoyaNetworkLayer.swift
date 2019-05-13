//
//  MoyaNetworkLayer.swift
//  MFSCalendar
//
//  Created by David Dai on 2017/6/9.
//  Copyright © 2017年 David. All rights reserved.
//

import Foundation
import Moya
import Alamofire

let provider = MoyaProvider<MyService>()

enum MyService {
    //myMFS
    case downloadLargeProfilePhoto(link: String)
    case getProfile(userID: String, token: String)
    case getPossibleContent(sectionId: String)
    case getContentList(sectionId: String)
    case getClassContentData(contentName: String, sectionId: String)
    case sectionInfoView(sectionID: String)
    case getSchedule(userID: String, startTime: String, endTime: String)

    //Dwei
    case getCalendarData
    case getCalendarEvent
    case dataVersionCheck
    case getQuarterSchedule
    case meetTimeSearch(classId: String)
    case getSteps(date: String)
    case reportSteps(steps: String, username: String, link: String)
    case getStepPoints(username: String)
    case getAllEmails(username: String, password: String)
    case getEmailWithID(username: String, password: String, id: String)
}

fileprivate let assetDir: URL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.org.dwei.MFSCalendar")!

extension MyService: TargetType {
    var headers: [String : String]? {
        return nil
    }
    

    var baseURL: URL {
        switch self {
        case .getCalendarData, .getCalendarEvent, .dataVersionCheck, .meetTimeSearch, .getQuarterSchedule, .getSteps, .reportSteps, .getStepPoints:
            return URL(string: Preferences().davidBaseURL)!
        case .getAllEmails, .getEmailWithID:
            return URL(string: Preferences().davidBaseURL)!
        default:
            return URL(string: Preferences().baseURL)!
        }
    }
    var path: String {
        switch self {
                //myMFS
        case .downloadLargeProfilePhoto(let link):
            print(link)
            return "\(link)"
        case .getProfile(let userID, _):
            return "/api/user/\(userID)/"
        case .getPossibleContent:
            return "/api/datadirect/BulletinBoardContentGet/"
        case .getContentList:
            return "/api/datadirect/GroupPossibleContentGet/"
        case .getClassContentData(let contentName, let sectionId):
            return "/api/\(contentName)/forsection/\(sectionId)/"
        case .sectionInfoView:
            return "/api/datadirect/SectionInfoView/"
        case .getSchedule:
            return "/api/DataDirect/ScheduleList/"

                // Dwei
        case .getCalendarData:
            return "/data"
        case .getCalendarEvent:
            return "/events.plist"
        case .dataVersionCheck:
            return "/dataversion"
        case .meetTimeSearch(let classId):
            return "/searchbyid/" + classId
        case .getQuarterSchedule:
            return "/quarterdata"
        case .getSteps(let date):
            return "/getSteps/" + date
        case .reportSteps:
            return "/recordSteps"
        case .getStepPoints(let username):
            return "/getStepPoints/" + username
        case .getAllEmails(let username, let password):
            return "/email/all/" + username + "/" + password
        case .getEmailWithID:
            return "/email/searchByID"
        }
    }

    var assetName: String {
        switch self {
        case .downloadLargeProfilePhoto: return "/ProfilePhoto.png"
        case .getCalendarEvent: return "/Events.plist"
        default: return ""
        }
    }

    var localLocation: URL {
        return assetDir.appendingPathComponent(assetName)
    }

    var method: Moya.Method {
        switch self {
        case .reportSteps, .getEmailWithID:
            return .post
        default:
            return .get
        }
    }

    var parameters: [String: Any]? {
        switch self {
        case .getProfile(_, let token):
            return ["t": token, "format": "json"]
        case .getPossibleContent(let sectionId):
            return ["format": "json", "sectionId": sectionId, "associationId": "1", "pendingInd": "false"]
        case .getContentList(let sectionId):
            return ["format": "json", "SectionId": sectionId]
        case .getClassContentData:
            return ["format": "json", "editMode": "false", "active": "true", "future": "false", "expired": "false", "contextLabelId": "2"]
        case .sectionInfoView(let sectionID):
            return ["format": "json", "sectionId": sectionID, "associationId": "1"]
        case .reportSteps(let steps, let username, let link):
            return ["name": username, "link": link, "steps": steps]
        case .getSchedule(let userID, let startTime, let endTime):
            return ["format": "json", "viewerID": userID, "personaId": "2", "viewerPersonaId": "2", "start": startTime, "end": endTime]
        case .getEmailWithID(let username, let password, let id):
            return ["name": username, "password": password, "id": id]
        default: return nil
        }
    }

    var parameterEncoding: ParameterEncoding {
        return URLEncoding.default
//      URLEncoding.default: Send parameters in URL for GET, DELETE and HEAD. For other HTTP methods, parameters will be sent in request body
//      URLEncoding.queryString: Always sends parameters in URL, regardless of which HTTP method is used
    }

    var sampleData: Data {
        return Data()
    }

    var downloadDestination: DownloadDestination {
        return { _, _ in
            return (self.localLocation, .removePreviousFile)
        }
    }

    var task: Task {
        switch self {
        case .downloadLargeProfilePhoto, .getCalendarEvent:
            return .downloadDestination(downloadDestination)
        default:
            return .requestParameters(parameters: parameters ?? [:], encoding: parameterEncoding)
        }
    }
}
