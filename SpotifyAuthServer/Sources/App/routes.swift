import Vapor
import Foundation

struct SpotifyResponse {
    let access_token: String?
    let token_type: String?
    let scope: String?
    let expires_in: Int?
    let refresh_token: String?
    let error: String?
}

extension SpotifyResponse: Content {
    static var defaultContentType: HTTPMediaType = .json
}

struct SpotifyConfigurate {
    let clientID = "871729f590414711839f544f7b4a809d"
    let secret = "bf131ca11a954424bb9a4652c023c1a9"
    let redirectURI = "testschema://callback"
    let tokenURL = "https://accounts.spotify.com/api/token"
    let swapURL = "http://192.168.0.143:1333/swap"
    let refreshURL = "http://192.168.0.143:1333/refresh"
}

func routes(_ app: Application) throws {
    
    //curl -d "code=NgAagA...NUm_SHo" -H "Content-Type: application/x-www-form-urlencoded" -X POST http://localhost:1333/swap
    app.post("swap") { (req) -> EventLoopFuture<SpotifyResponse> in
        struct RequestBody: Content {
            static var defaultContentType: HTTPMediaType = .urlEncodedForm
            let code: String
        }
        
        struct ClientBody: Content {
            static var defaultContentType: HTTPMediaType = .urlEncodedForm
            let grant_type = "authorization_code"
            let code: String
            let redirect_uri: String
        }
        
        let code = try req.content.decode(RequestBody.self).code
        app.logger.debug("code = \(code)")

        let configurate = SpotifyConfigurate()
        let clientID = configurate.clientID
        let clientSecret = configurate.secret
        let redirect_uri = configurate.redirectURI

        var headers = HTTPHeaders()
        let base64 = "\(clientID):\(clientSecret)".data(using: .utf8)!.base64EncodedString()
        headers.add(name: "Authorization", value: "Basic \(base64)")
        
        return req.client.post(URI(string: configurate.tokenURL), headers: headers) { (clientReq) in
            let body = ClientBody(code: code, redirect_uri: redirect_uri)
            try clientReq.content.encode(body)
        }.flatMapThrowing { (clientResponse) -> SpotifyResponse in
            return try clientResponse.content.decode(SpotifyResponse.self)
        }
    }
    
    //curl -d "refresh_token=NgAagA...NUm_SHo" -H "Content-Type: application/x-www-form-urlencoded" -X POST http://localhost:1333/refresh
    app.post("refresh") { (req) -> EventLoopFuture<SpotifyResponse> in
        struct RequestBody: Content {
            static var defaultContentType: HTTPMediaType = .urlEncodedForm
            let refresh_token: String
        }
        
        struct ClientBody: Content {
            static var defaultContentType: HTTPMediaType = .urlEncodedForm
            let grant_type = "refresh_token"
            let refresh_token: String
        }
        
        let refresh_token = try req.content.decode(RequestBody.self).refresh_token
        app.logger.debug("refresh_token = \(refresh_token)")

        let configurate = SpotifyConfigurate()

        let clientID = configurate.clientID
        let clientSecret = configurate.secret
        var headers = HTTPHeaders()
        let auth = BasicAuthorization(username: clientID, password: clientSecret)
        headers.basicAuthorization = auth
        
        return req.client.post(URI(string: configurate.tokenURL), headers: headers) { (clientReq) in
            let body = ClientBody(refresh_token: refresh_token)
            try clientReq.content.encode(body)
        }.flatMapThrowing { (clientResponse) -> SpotifyResponse in
            return try clientResponse.content.decode(SpotifyResponse.self)
        }
    }
}
