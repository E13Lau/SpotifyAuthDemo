//
//  SpotifyArtistsApi.swift
//  SpotifyAuthDemo
//
//  Created by lau on 2020/5/30.
//

protocol ResourceArtistsAPI { }
extension SpotifyAPI where Self: ResourceArtistsAPI {
    var resource: String {
        return "artists"
    }
}

struct SPTGetArtistsApi: SpotifyAPIVersion1, GetAPI, ResourceArtistsAPI {
    var path: String {
        return "\(id)"
    }
    
    var query: [String : String] {
        return [:]
    }
    
    typealias Response = SpotifyArtist
    
    let id: String
}

struct SPTGetArtistsAlbumsApi: SpotifyAPIVersion1, GetAPI, ResourceArtistsAPI {
    var path: String {
        return "\(id)/albums"
    }
    
    var query: [String : String] {
        return [:]
    }
    
    typealias Response = SpotifyPaging<SpotifyAlbumSimple>

    let id: String
}

struct SPTGetArtistsTopTracksApi: SpotifyAPIVersion1,GetAPI, ResourceArtistsAPI {
    typealias Response = Model
    struct Model: Codable {
        let tracks: [SpotifyTracks]
    }
    
    var query: [String : String] {
        return ["country": country]
    }
    
    var path: String {
        return "\(id)/top-tracks"
    }
    
    let id: String
    let country: String
    
}

struct SPTGetArtistsRelatedArtistsApi: SpotifyAPIVersion1, GetAPI, ResourceArtistsAPI {
    typealias Response = Model
    struct Model: Codable {
        let artists: [SpotifyArtist]
    }
    
    var query: [String : String] {
        return [:]
    }
    
    var path: String {
        return "\(id)/related-artists"
    }
    
    let id: String
}


struct SPTGetSeveralArtistsApi: SpotifyAPIVersion1, GetAPI, ResourceArtistsAPI {
    var path: String {
        return ""
    }
    
    var query: [String : String] {
        let string = ids.joined(separator: ",")
        return ["ids" : string]
    }
    
    typealias Response = Model
    struct Model: Codable {
        let artists: [SpotifyArtist]
    }

    let ids: [String]
}
