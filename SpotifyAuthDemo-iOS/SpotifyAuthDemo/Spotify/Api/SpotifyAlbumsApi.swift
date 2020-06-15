//
//  SpotifyAlbumsApi.swift
//  SpotifyAuthDemo
//
//  Created by lau on 2020/5/30.
//

protocol ResourceAlbumsAPI { }
extension SpotifyAPI where Self: ResourceAlbumsAPI {
    var resource: String {
        return "albums"
    }
}

struct SPTGetAlbumApi: SpotifyAPIVersion1, ResourceAlbumsAPI, GetAPI {
    var path: String {
        return "\(id)"
    }
    
    var query: [String : String] {
        guard let market = self.market else {
            return [:]
        }
        return ["market": market]
    }
    
    typealias Response = SpotifyAlbum
    
    let id: String
    var market: String? = nil

}

struct SPTGetAlbumsTracksApi: SpotifyAPIVersion1, GetAPI, ResourceAlbumsAPI {
    var path: String {
        return "\(id)/tracks"
    }
    
    var query: [String : String] {
        var dict = [String: String]()
        if var limit = self.limit {
            if limit > 50 {
                limit = 50
            }
            dict["limit"] = "\(limit)"
        }
        if let offset = self.offset {
            dict["offset"] = "\(offset)"
        }
        if let market = self.market {
            dict["market"] = market
        }
        return dict
    }
    
    let id: String
    var limit: Int?
    var offset: Int?
    var market: String?
    
    typealias Response = SpotifyPaging<SpotifyTrackSimple>
}

struct SPTGetSeveralAlbumsApi: SpotifyAPIVersion1, GetAPI, ResourceAlbumsAPI {
    typealias Response = SPTGetSeveralAlbumsResponse
    struct SPTGetSeveralAlbumsResponse: Codable {
        let albums: [SpotifyAlbum]?
    }
    
    var path: String {
        return ""
    }
    var query: [String : String] {
        var dict = [String: String]()
        dict["ids"] = ids.joined(separator: ",")
        if let market = self.market {
            dict["market"] = market
        }
        return dict
    }
    
    let ids: [String]
    var market: String?
}
