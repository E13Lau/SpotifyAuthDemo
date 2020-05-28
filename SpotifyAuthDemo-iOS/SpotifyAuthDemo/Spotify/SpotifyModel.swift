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
struct SpotifyUserProfile: Codable, SpotifyErrorModel {
    struct Image: Codable {
        let height: Int?
        let url: String
        let width: Int?
    }
    struct Followers: Codable {
        let href: String?
        let total: Int?
    }
    let country: String?
    let display_name: String?
    let email: String?
    let followers: Followers?
    let href: String?
    let id: String?
    let images: [Image]?
    let product: String?
    let type: String?
    let uri: String?
    var error: SpotifyError?
}

struct SpotifyError: Codable {
    let status: Int?
    let message: String?
}

protocol SpotifyErrorModel {
    var error: SpotifyError? { get set }
}
