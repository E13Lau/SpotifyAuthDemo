import Foundation

struct SpotifyConfigurate {
    let clientID = "xxxxxxxx"
    let redirectURI = "xxxxxxxxx"
    var swapURLTest: String {
        return "https://192.168.1.5/app/tokenSwap"
    }
    var refreshURLTest: String {
        return "https://192.168.1.5/app/tokenRefresh"
    }
    
    var requestedScopes: SPTScope {
        return [.streaming,
                .playlistReadPrivate,
                .playlistReadCollaborative,
                .userFollowModify,
                .userFollowRead,
                .userLibraryRead,
                .userReadPrivate,
                .userTopRead,
                .playlistModifyPublic,
                .playlistModifyPrivate]
    }
    var requestedScopesString: [String] {
        return ["streaming",
                "playlist-read-private",
                "playlist-read-collaborative",
                "user-follow-modify",
                "user-follow-read",
                "user-library-read",
                "user-top-read",
                "playlist-modify-public",
                "playlist-modify-private",
                "user-read-private",
                ]
    }
}

struct SpotifyToken {
    let accessToken: String?
    let refreshToken: String?
    //default 3600
    let expiresIn: TimeInterval?
    let expirationDate: TimeInterval?
    let error: String?
    ///创建日期
    let createAt: Date
    ///过期日期
    var expiresAt: Date {
        if let exDate = expirationDate {
            return Date(timeIntervalSinceReferenceDate: exDate)
        }
        if let ex = expiresIn {
            return createAt.addingTimeInterval(ex)
        }
        return createAt.addingTimeInterval(3600)
    }
    
    init(error: String?) {
        self.error = error
        self.accessToken = nil
        self.refreshToken = nil
        self.expiresIn = nil
        self.expirationDate = nil
        self.createAt = Date()
    }
    
    init(accessToken: String?, refreshToken: String?, expiresIn: TimeInterval?, expirationDate: TimeInterval?, createAt: Date = Date()) {
        self.error = nil
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresIn = expiresIn
        self.expirationDate = expirationDate
        self.createAt = createAt
    }
    
    //是否有效
    var isExpiry: Bool {
        if error != nil {
            return false
        }
        return expiresAt > Date()
    }
    //是否接近无效
    var isNearInvalid: Bool {
        let now = Date()
        if expiresAt > now {
            let c = expiresAt.timeIntervalSinceReferenceDate
            let n = now.timeIntervalSinceReferenceDate
            if (c - n) <= 300 {
                return true
            }
        }
        return false
    }
    var deadline: TimeInterval {
        let now = Date()
        if error != nil {
            return 0
        }
        if expiresAt <= now {
            return 0
        }
        return expiresAt.timeIntervalSinceReferenceDate - now.timeIntervalSinceReferenceDate
    }
}

extension SpotifyToken: Codable { }
struct SpotifyUserProfile: Codable, SpotifyRegularErrorObject {
    let country: String?
    let display_name: String?
    let email: String?
    let followers: SpotifyFollowers?
    let href: String?
    let id: String?
    let images: [SpotifyImage]?
    let product: String?
    let type: String?
    let uri: String?
    var error: SpotifyError?
}

protocol SpotifyAuthenticationErrorObject {
    var error: String? { get set }
    var error_description: String? { get set }
}
protocol SpotifyRegularErrorObject {
    var error: SpotifyError? { get set }
}

struct SpotifyError: Codable {
    let status: ResponseStatusCodes?
    let message: String?
}

enum ResponseStatusCodes: Int, Codable, Equatable {
    ///OK - The request has succeeded. The client can read the result of the request in the body and the headers of the response.
    case ok = 200
    
    ///Created - The request has been fulfilled and resulted in a new resource being created.
    case created = 201
    
    ///Accepted - The request has been accepted for processing, but the processing has not been completed.
    case accepted = 202
    
    ///No Content - The request has succeeded but returns no message body.
    case noContent = 204
    
    ///Not Modified. See Conditional requests.
    case notModified = 304
    
    ///Bad Request - The request could not be understood by the server due to malformed syntax. The message body will contain more information; see Response Schema.
    case badRequest = 400
    
    ///Unauthorized - The request requires user authentication or, if the request included authorization credentials, authorization has been refused for those credentials.
    case unauthorized = 401
    
    ///Forbidden - The server understood the request, but is refusing to fulfill it.
    case forbidden = 403
    
    ///Not Found - The requested resource could not be found. This error can be due to a temporary or permanent condition.
    case notFound = 404
    
    ///Too Many Requests - Rate limiting has been applied.
    case tooManyRequest = 429
    
    ///Internal Server Error. You should never receive this error because our clever coders catch them all … but if you are unlucky enough to get one, please report it to us through a comment at the bottom of this page.
    case internalServerError = 500
    
    ///Bad Gateway - The server was acting as a gateway or proxy and received an invalid response from the upstream server.
    case badGateway = 502
    
    ///Service Unavailable - The server is currently unable to handle the request due to a temporary condition which will be alleviated after some delay. You can choose to resend the request again.
    case serviceUnavailable = 503
}

typealias ExternalObject = [String: String]
struct SpotifyCopyright: Codable {
    let text: String?
    let type: String?
}

struct SpotifyImage: Codable {
    let height: Int?
    let width: Int?
    let url: String?
}

struct SpotifyAlbum: Codable {
    let album_type: String?
    let artists: [SpotifyArtist]?
    let available_markets: [String]?
    let copyrights: [SpotifyCopyright]?
    let external_ids: ExternalObject?
    let external_urls: ExternalObject?
    let genres: [String]?
    let href: String?
    let id: String?
    let images: [SpotifyImage]?
    let label: String?
    let name: String?
    let popularity: Int?
    let release_date: String?
    let release_date_precision: String?
    let restrictions: [String: String]?
    let tracks: SpotifyPaging<SpotifyTrackSimple>?
    let type: String?
    let uri: String?
}

struct SpotifyAlbumSimple: Codable {
    let album_group: String?
    let album_type: String?
    let artists: [SpotifyArtist]
}

struct SpotifyTracks: Codable {
    struct items: Codable {
        let external_urls: [String: String]?
        let uri: String?
        let track_number: Int?
        let preview_url: String?
        let explicit: Int?
        let id: String?
        let type: String?
        let available_markets: [String]?
        let name: String?
        let href: String?
        struct artists: Codable {
            let uri: String?
            let href: String?
            let type: String?
            let name: String?
            let id: String?
            let external_urls: [String: String]?
        }
        let artists: [artists]?
        let disc_number: Int?
        let duration_ms: Int?
    }
    let items: [items]?
    let limit: Int?
    let next: String?
    let href: String?
    let total: Int?
    let previous: String?
    let offset: Int?
}

struct SpotifyTrackSimple: Codable {
    let artists: [SpotifyArtist]?
    let available_markets: [String]?
    let disc_number: Int?
    let duration_ms: Int?
    let explicit: Bool?
    let external_urls: ExternalObject?
    let href: String?
    let id: String?
    let is_playable: Bool?
    let linked_from: SpotifyTrackLink?
    let restrictions: [String: String]?
    let name: String?
    let preview_url: String?
    let track_number: Int?
    let type: String?
    let uri: String?
    let is_local: Bool?
}

struct SpotifyTrackLink: Codable {
    let external_urls: ExternalObject?
    let href: String?
    let id: String?
    let type: String?
    let uri: String?
}

struct SpotifyEpisode: Codable {
    let audio_preview_url: String?
    let description: String?
    let duration_ms: Int?
    let explicit: Bool?
    let external_urls: ExternalObject?
    let href: String?
    let id: String?
    let images: [SpotifyImage]?
    let is_externally_hosted: Bool?
    let is_playable: Bool?
    let language: String?
    let languages: [String]?
    let name: String?
    let release_date: String?
    let release_date_precision: String?
    let resume_point: SpotifyResumePoint?
    let show: SpotifyShowSimple?
    let type: String?
    let uri: String?
}

struct SpotifyEpisodeSimple: Codable {
    let audio_preview_url: String?
    let description: String?
    let duration_ms: Int?
    let explicit: Bool?
    let external_urls: ExternalObject?
    let href: String?
    let id: String?
    let images: [SpotifyImage]?
    let is_externally_hosted: Bool?
    let is_playable: Bool?
    let language: String?
    let languages: [String]?
    let name: String?
    let release_date: String?
    let release_date_precision: String?
    let resume_point: SpotifyResumePoint?
    let type: String?
    let uri: String?
}

struct SpotifyResumePoint: Codable {
    let fully_played: Bool?
    let resume_position_ms: Int?
}

struct SpotifyShowSimple: Codable {
    let available_markets: [String]?
    let copyrights: [SpotifyCopyright]?
    let description: String?
    let explicit: Bool?
    let external_urls: ExternalObject?
    let href: String?
    let id: String?
    let images: [SpotifyImage]?
    let is_externally_hosted: Bool?
    let languages: [String]?
    let media_type: String?
    let name: String?
    let publisher: String?
    let type: String?
    let uri: String?
}

struct SpotifyShow: Codable {
    let available_markets: [String]?
    let copyrights: [SpotifyCopyright]?
    let description: String?
    let explicit: Bool?
    let episodes: SpotifyPaging<SpotifyEpisode>?
    let external_urls: ExternalObject?
    let href: String?
    let id: String?
    let images: [SpotifyImage]?
    let is_externally_hosted: Bool?
    let languages: [String]?
    let media_type: String?
    let name: String?
    let publisher: String?
    let type: String?
    let uri: String?
}

struct SpotifyUserPrivate: Codable {
    let country: String?
    let display_name: String?
    let email: String?
    let external_urls: ExternalObject?
    let followers: SpotifyFollowers?
    let href: String?
    let id: String?
    let images: [SpotifyImage]?
    let product: String?
    let type: String?
    let uri: String?
}

struct SpotifyUserPublic: Codable {
    let display_name: String?
    let external_urls: ExternalObject?
    let followers: SpotifyFollowers?
    let href: String?
    let id: String?
    let images: [SpotifyImage]?
    let type: String?
    let uri: String?
}

struct SpotifyFollowers: Codable {
    let total: Int?
    let href: String?
}

struct SpotifyArtist: Codable {
    let external_urls: [String: String]?
    let followers: SpotifyFollowers?
    let genres: [String]?
    let href: String?
    let id: String?
    let images: [SpotifyImage]?
    let name: String?
    let popularity: Int?
    let type: String?
    let uri: String?
}

struct SpotifyArtistSimple: Codable {
    let external_urls: [String: String]?
    let href: String?
    let id: String?
    let name: String?
    let type: String?
    let uri: String?
}

struct SpotifyAudioFeatures: Codable {
    ///0.0 ... 1.0
    let acousticness: Float?
    let analysis_url: String?
    ///0.0 ... 1.0
    let danceability: Float?
    let duration_ms: Int?
    let energy: Float?
    let id: String?
    let instrumentalness: Float?
    let key: Int?
    let liveness: Float?
    let loudness: Float?
    let mode: Int?
    let speechiness: Float?
    let tempo: Float?
    let time_signature: Int?
    let track_href: String?
    let type: String?
    let uri: String?
    ///0.0 ... 1.0
    let valence: Float?
}

struct SpotifyCategory: Codable {
    let href: String?
    let icons: [SpotifyImage]?
    let id: String?
    let name: String?
}

struct SpotifyContext: Codable {
    let type: String?
    let href: String?
    let external_urls: [String: String]?
    let uri: String?
}

struct SpotifyPlayerError: Codable {
    let status: String?
    let message: String?
    let reason: String?
}

struct SpotifyPaging<T: Codable>: Codable {
    let href: String?
    let items: [T]?
    let limit: Int?
    let next: String?
    let offset: Int?
    let previous: String?
    let total: Int?
}

struct SpotifyCursorbasedPaging<T: Codable>: Codable {
    let href: String?
    let items: [T]?
    let limit: Int?
    let next: String?
    struct Cursor: Codable {
        let after: String?
    }
    let cursors: [Cursor]?
    let total: Int?
}

struct SpotifyPlayHistory: Codable {
    let track: SpotifyTracks?
    let played_at: String?
    let context: SpotifyContext?
}

struct SpotifyPlaylistSimple: Codable {
    let collaborative: Bool?
    let description: String?
    let external_urls: ExternalObject?
    let href: String?
    let id: String?
    let images: [SpotifyImage]
    let name: String?
    let owner: SpotifyUserPublic?
    let `public`: Bool?
    let snapshot_id: String?
    let tracks: SpotifyPaging<SpotifyPlaylistTrack<SpotifyTracks>>?
    let type: String?
    let uri: String?
}

struct SpotifyPlaylistTrack<T: Codable>: Codable {
    let added_at: Date?
    let added_by: SpotifyUserPublic?
    let is_local: Bool?
    //a track object or a episode object
    let track: T?
}

struct SpotifyRecommenddationsSeed: Codable {
    let afterFilteringSize: Int?
    let afterRelinkingSize: Int?
    let href: String?
    let id: String?
    let initialPoolSize: Int?
    let type: String?
}

enum NoContentable<T: Codable>: Codable {
    enum Key: CodingKey {
        case noContent
        case response
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Key.self)
        do {
            let res = try container.decode(T.self, forKey: .response)
            self = .response(res)
        } catch {
            self = .noContent
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: Key.self)
        switch self {
        case .noContent:
            try container.encodeNil(forKey: .noContent)
        case .response(let response):
            try container.encode(response, forKey: .response)
        }
    }
    
    case noContent
    case response(T)
}
