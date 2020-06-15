//
//  SpotifyFollowApi.swift
//  SpotifyAuthDemo
//
//  Created by lau on 2020/5/30.
//

import Foundation

protocol ResourceFollowingAPI { }
extension SpotifyAPI where Self: ResourceFollowingAPI {
    var resource: String {
        return "following"
    }
}

struct SPTCheckIsFollowsSomeoneApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    let type: String
    let ids: [String]
    
    var path: String {
        return "following/contains"
    }
    
    var query: [String : String] {
        if ids.count > 50 {
            fatalError("A maximum of 50 IDs can be sent in one request.")
        }
        let string = ids.joined(separator: ",")
        return ["type": type, "ids": string]
    }
    
    typealias Response = [Bool]
}

struct SPTCheckIsFollowPlaylistApi: SpotifyAPIVersion1, GetAPI, ResourcePlaylistsAPI {
    let playlist_id: String
    let ids: [String]
    var path: String {
        return "\(playlist_id)/followers/contains"
    }
    
    var query: [String : String] {
        if ids.count > 5 {
            fatalError("the ids of the users that you want to check to see if they follow the playlist. Maximum: 5 ids.")
        }
        let string = ids.joined(separator: ",")
        return ["ids": string]
    }
    
    typealias Response = [Bool]
    
}

struct SPTFollowSomeoneApi: SpotifyAPIVersion1, PUTAPI, ResourceMeAPI {
    var path: String {
        return "following"
    }
    
    var query: [String : String] {
        return [:]
    }
    enum `Type`: String {
        case artist, user
    }
    let type: Type
    let ids: [String]?
    
    var params: [String : Any] {
        var dict = [String: Any]()
        dict["type"] = type
        if let ids = ids {
            if ids.count > 50 {
                fatalError("A maximum of 50 IDs can be sent in one request.")
            }
            dict["ids"] = ids.joined(separator: ",")
        }
        return dict
    }
    
    // mean "No Content"
    typealias Response = String
    
}

struct SPTFollowPlaylistApi: SpotifyAPIVersion1, PUTAPI, ResourcePlaylistsAPI {
    
    let playlist_id: String
    let `public`: Bool?
    
    var path: String {
        return "/\(playlist_id)/followers"
    }
    
    var params: [String : Any] {
        return ["public": self.public ?? true]
    }
    
    var query: [String : String] {
        return [:]
    }

    typealias Response = String
    
}

struct SPTGetUserFollowedArtistsApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    var query: [String : String] {
        var dict = [String: String]()
        dict["type"] = type.rawValue
        dict["limit"] = "\(limit ?? 20)"
        if let offset = after {
            dict["offset"] = "\(offset)"
        }
        return dict
    }
    
    typealias Response = Model
    
    struct Model: Codable {
        let artists: SpotifyPaging<SpotifyArtist>
    }
    enum `Type`: String {
        case artist, user
    }
    let type: Type
    let limit: Int?
    let after: String?
    
    var path: String {
        return "following"
    }
    
}

struct SPTUnfollowSomeoneApi: SpotifyAPIVersion1, DeleteAPI, ResourceMeAPI {
    var params: [String : Any] {
        return [:]
    }
    
    enum `Type`: String {
        case artist, user
    }
    let type: Type
    let ids: [String]?
    
    var path: String {
        return "following"
    }
    
    var query: [String : String] {
        var dict = [String: String]()
        dict["type"] = type.rawValue
        if let ids = self.ids {
            if ids.count > 50 {
                fatalError("A maximum of 50 IDs can be sent in one request.")
            }
            dict["ids"] = ids.joined(separator: ",")
        }
        return dict
    }
    
    var bodyData: Data? {
        return nil
    }
    
    typealias Response = String
}

struct SPTUnfollowPlaylistApi: SpotifyAPIVersion1, DeleteAPI, ResourcePlaylistsAPI {
    
    let playlist_id: String
    
    var path: String {
        return "\(playlist_id)/followers"
    }
    
    var query: [String : String] {
        return [:]
    }
    
    var params: [String : Any] {
        return [:]
    }
    
    typealias Response = String
}

