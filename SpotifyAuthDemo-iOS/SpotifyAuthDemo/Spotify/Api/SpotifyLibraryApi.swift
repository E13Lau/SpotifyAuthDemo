//
//  SpotifyLibraryApi.swift
//  SpotifyAuthDemo
//
//  Created by lau on 2020/5/30.
//

import Foundation

struct SPTCheckUserSavedAlbumsApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    var path: String {
        return "albums/contains"
    }
    
    let ids: [String]
    
    var query: [String : String] {
        if ids.count > 50 {
            fatalError("Maximum: 50 IDs.")
        }
        let string = ids.joined(separator: ",")
        return ["ids": string]
    }
    
    typealias Response = [Bool]
}

struct SPTCheckUserSavedShowsApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    var path: String {
        return "shows/contains"
    }
    
    let ids: [String]
    
    var query: [String : String] {
        if ids.count > 50 {
            fatalError("Maximum: 50 IDs.")
        }
        let string = ids.joined(separator: ",")
        return ["ids": string]
    }
    
    typealias Response = [Bool]
}

struct SPTCheckUserSavedTracksApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    var path: String {
        return "tracks/contains"
    }
    
    let ids: [String]
    
    var query: [String : String] {
        if ids.count > 50 {
            fatalError("Maximum: 50 IDs.")
        }
        let string = ids.joined(separator: ",")
        return ["ids": string]
    }
    
    typealias Response = [Bool]
}

struct SPTGetCurrentUserSavedAlbumsApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    var limit: Int?
    var offset: Int?
    let market: String?
    
    var path: String {
        return "albums"
    }
    
    var query: [String : String] {
        var dict = [String: String]()
        let limit = self.limit ?? 20
        dict["limit"] = "\(limit)"
        let offset = self.offset ?? 0
        dict["offset"] = "\(offset)"
        if let market = self.market {
            dict["market"] = market
        }
        return dict
    }
    
    typealias Response = SpotifyPaging<Model>
    struct Model: Codable {
        let added_at: Date?
        let album: SpotifyAlbum?
    }
}

struct SPTGetUserSavedShowsApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    var limit: Int?
    var offset: Int?
    
    var query: [String : String] {
        var dict = [String: String]()
        let limit = self.limit ?? 20
        dict["limit"] = "\(limit)"
        let offset = self.offset ?? 0
        dict["offset"] = "\(offset)"
        return dict
    }
    
    var path: String {
        return "shows"
    }

    typealias Response = SpotifyPaging<Model>
    struct Model: Codable {
        let added_at: Date?
        let show: SpotifyShowSimple?
    }
}

struct SPTGetUserSavedTracksApi: SpotifyAPIVersion1, GetAPI, ResourceMeAPI {
    var limit: Int?
    var offset: Int?
    let market: String?

    var query: [String : String] {
        var dict = [String: String]()
        let limit = self.limit ?? 20
        dict["limit"] = "\(limit)"
        let offset = self.offset ?? 0
        dict["offset"] = "\(offset)"
        if let market = self.market {
            dict["market"] = market
        }
        return dict
    }
    
    var path: String {
        return "tracks"
    }
    
    typealias Response = SpotifyPaging<Model>
    struct Model: Codable {
        let added_at: Date?
        let track: SpotifyTracks?
    }
}

struct SPTRemoveAlbumsApi: SpotifyAPIVersion1, DeleteAPI, ResourceMeAPI {
    let ids: [String]?
    
    var path: String {
        return "ablums"
    }
    
    var query: [String : String] {
        return [:]
    }
    
    var params: [String : Any] {
        guard let ids = self.ids else {
            return [:]
        }
        guard ids.count <= 50 else {
            fatalError("Maximum: 50 IDs.")
        }
        return ["ids": ids.joined(separator: ",")]
    }
    
    typealias Response = String
}

struct SPTRemoveUserSavedShowsApi: SpotifyAPIVersion1, DeleteAPI, ResourceMeAPI {
    
    var params: [String : Any] {
        return [:]
    }
    
    var path: String {
        return "shows"
    }
    
    let ids: [String]
    let market: String?
    var query: [String : String] {
        var dict: [String: String] = [:]
        dict["ids"] = ids.joined(separator: ",")
        if let market = market {
            return ["market": market]
        }
        return dict
    }
    
    typealias Response = String
}

struct SPTRemoveUserSavedTracksApi: SpotifyAPIVersion1, DeleteAPI, ResourceMeAPI {
    
    var params: [String : Any] {
        return [:]
    }
    
    var path: String {
        return "tracks"
    }
    
    let ids: [String]
    let market: String?
    var query: [String : String] {
        var dict: [String: String] = [:]
        dict["ids"] = ids.joined(separator: ",")
        if let market = market {
            return ["market": market]
        }
        return dict
    }
    
    typealias Response = String
}

struct SPTSaveAlbumsApi: SpotifyAPIVersion1, PUTAPI, ResourceMeAPI {
    var path: String {
        return "albums"
    }
    
    let ids: [String]?
    
    var params: [String : Any] {
        var dict: [String: Any] = [:]
        guard let ids = self.ids else {
            return dict
        }
        guard ids.count <= 50 else {
            return dict
        }
        dict["ids"] = ids.joined(separator: ",")
        return dict
    }
    
    var query: [String : String] {
        return [:]
    }
    
    typealias Response = String
}

struct SPTSaveShowsApi: SpotifyAPIVersion1, PUTAPI, ResourceMeAPI {
    var path: String {
        return "shows"
    }
    
    let ids: [String]?
    
    var params: [String : Any] {
        return [:]
    }
    
    var query: [String : String] {
        var dict: [String: String] = [:]
        guard let ids = self.ids else {
            return dict
        }
        guard ids.count <= 50 else {
            return dict
        }
        dict["ids"] = ids.joined(separator: ",")
        return dict
    }
    
    typealias Response = String
}

struct SPTSaveTracksApi: SpotifyAPIVersion1, PUTAPI, ResourceMeAPI {
    var path: String {
        return "tracks"
    }
    
    let ids: [String]?
    
    var params: [String : Any] {
        return [:]
    }
    
    var query: [String : String] {
        var dict: [String: String] = [:]
        guard let ids = self.ids else {
            return dict
        }
        guard ids.count <= 50 else {
            return dict
        }
        dict["ids"] = ids.joined(separator: ",")
        return dict
    }
    
    typealias Response = String
}
