//
//  SpotifySearchApi.swift
//  SpotifyAuthDemo
//
//  Created by lau on 2020/5/30.
//

protocol ResourceSearchAPI { }
extension SpotifyAPI where Self: ResourceSearchAPI {
    var resource: String {
        return "search"
    }
}

//https://developer.spotify.com/documentation/web-api/reference/search/search/
struct SPTSearchApi: SpotifyAPIVersion1, ResourceSearchAPI, GetAPI {
    typealias Response = Dictionary<String, Any>
    enum SearchType: String {
        case album, artist, playlist, track, show, episode
    }
    var query: [String : String] {
        let type = self.type.map({ $0.rawValue }).joined(separator: ",")
        var dict = ["q": self.q, "type": type]
        if let value = self.market {
            dict["market"] = value
        }
        if let value = self.limit {
            dict["limit"] = value
        }
        if let value = self.offset {
            dict["offset"] = value
        }
        if let value = self.include_external {
            dict["include_external"] = value
        }
        return dict
    }
    var path: String {
        return ""
    }
    
    let q: String
    let type: [SearchType]
    
    let market: String?
    //default: 20, range [1...50]
    let limit: String?
    //default: 0, max: 2000
    let offset: String?
    let include_external: String?
}
