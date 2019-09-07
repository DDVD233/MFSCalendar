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
    case getEventsIDList(startDate: String, endDate: String)
    case downloadEventsFromMySchool(startDate: String, endDate: String, idList: [String])
    case getSchoolContext

    //Dwei
    case getCalendarData
    case getCalendarEvent
    case dataVersionCheck
    case getQuarterSchedule  // Deprecated
    case meetTimeSearch(classId: String) // Deprecated
    case getSteps(date: String)
    case reportSteps(steps: String, username: String, link: String)
    case getStepPoints(username: String)
    case getAllEmails(username: String, password: String)  // Not Yet Used
    case getEmailWithID(username: String, password: String, id: String)  // Not Yet Used
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
            return URL(string: Preferences().baseURL) ?? URL(string: "http://www.myschoolapp.com")!
        }
    }
    var path: String {
        switch self {
        // MAINTAIN: All functions below are from mySchool. Update these functions if any of them are updated on the myschool site.
        case .downloadLargeProfilePhoto(let link):
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
        case .getEventsIDList:
            return "/api/mycalendar/list/"
        case .downloadEventsFromMySchool:
            return "/api/mycalendar/events"
        case .getSchoolContext:
            return "/api/webapp/context"
        

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
            let personaId = Preferences().personaId ?? "2"
            return ["format": "json", "viewerId": userID, "personaId": personaId, "viewerPersonaId": personaId, "start": startTime, "end": endTime]
        case .getEmailWithID(let username, let password, let id):
            return ["name": username, "password": password, "id": id]
        case .getEventsIDList(let startDate, let endDate):
            return ["startDate": startDate, "endDate": endDate, "settingsTypeId": "1", "calendarSetId": "1"]
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
        case .downloadEventsFromMySchool(let startDate, let endDate, let idList):
            let filterString = idList.joined(separator: ",")
            let parameter = ["startDate": startDate, "endDate": endDate, "filterString": filterString, "showPractice": "false"] as [String : Any]
            return .requestParameters(parameters: parameter, encoding: parameterEncoding)
        default:
            return .requestParameters(parameters: parameters ?? [:], encoding: parameterEncoding)
        }
    }
}
