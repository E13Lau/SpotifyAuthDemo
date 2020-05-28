import Foundation
import WebKit
import Logging
import SafariServices

//MARK: SpotifyPersistenceToken protocol
protocol SpotifyPersistenceToken {
    func save(spotifyToken: SpotifyToken?)
    func removeSpotifyToken()
    func getSpotifyToken() -> SpotifyToken?
}

protocol SpotifyAuthControl {
    var tag: String { get }
    func initiateSession(_ viewController: UIViewController?) -> Bool
    func renewSession(refreshToken: String?) -> Bool
    func unlink()
    func application(app: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool
}

struct SpotifySaveTokenUserDefaults: SpotifyPersistenceToken {
    private let SpotifyTokenUserDefaultKey = "SpotifyTokenUserDefaultKey"
    func save(spotifyToken: SpotifyToken?) {
        guard let token = spotifyToken else {
            return
        }
        let encoder = JSONEncoder()
        guard let encoded = try? encoder.encode(token) else {
            return
        }
        let ud = UserDefaults.standard
        ud.set(encoded, forKey: SpotifyTokenUserDefaultKey)
    }
    
    func removeSpotifyToken() {
        let ud = UserDefaults.standard
        ud.removeObject(forKey: SpotifyTokenUserDefaultKey)
    }
    
    func getSpotifyToken() -> SpotifyToken? {
        let ud = UserDefaults.standard
        let object = ud.object(forKey: SpotifyTokenUserDefaultKey)
        guard let data = object as? Data else {
            return nil
        }
        let decoder = JSONDecoder()
        guard let token = try? decoder.decode(SpotifyToken.self, from: data) else {
            return nil
        }
        return token
    }
}

struct SpotifyAuthWithSDK: SpotifyAuthControl {
    
    init(config: SpotifyConfigurate, delegate: SPTSessionManagerDelegate) {
        let spotifyConfiguration = SPTConfiguration(clientID: config.clientID, redirectURL: URL(string: config.redirectURI)!)
        let tokenSwapURL: URL? = URL(string: config.swapURLTest)
        let tokenRefreshURL: URL? = URL(string: config.refreshURLTest)
        if let tokenSwapURL = tokenSwapURL,
            let tokenRefreshURL = tokenRefreshURL {
            spotifyConfiguration.tokenSwapURL = tokenSwapURL
            spotifyConfiguration.tokenRefreshURL = tokenRefreshURL
            spotifyConfiguration.playURI = ""
        }
        self.spotifySessionManager = SPTSessionManager(configuration: spotifyConfiguration, delegate: delegate)
        self.spotifySessionManager.alwaysShowAuthorizationDialog = false
        self.sptScope = config.requestedScopes
    }
    
    let spotifySessionManager: SPTSessionManager
    private let sptScope: SPTScope
    var tag: String {
        return "SDK"
    }

    func initiateSession(_ viewController: UIViewController? = nil) -> Bool {
        guard self.spotifySessionManager.isSpotifyAppInstalled else {
            return false
        }
        self.getSession()
        return true
    }
    
    private func getSession() {
        self.spotifySessionManager.initiateSession(with: self.sptScope, options: .default)
    }
    
    func renewSession(refreshToken: String?) -> Bool {
        if self.spotifySessionManager.session == nil {
            return false
        }
        self.spotifySessionManager.renewSession()
        return true
    }
    
    func application(app: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        guard self.spotifySessionManager.isSpotifyAppInstalled else {
            return false
        }
        return self.spotifySessionManager.application(app, open: url, options: options)
    }
    
    func unlink() {
        self.spotifySessionManager.session = nil
    }
}

protocol SpotifyAuthWithWebDelegate: class {
    func spotifyDidAuth(token: SpotifyToken?)
}

class SpotifyAuthWithWeb: SpotifyAuthControl {
    deinit {
        logger.debug("SpotifyAuthWithWeb deinit")
    }
    init(config: SpotifyConfigurate, delegate: SpotifyAuthWithWebDelegate) {
        self.spotifyConfig = config
        self.delegate = delegate
    }
    
    let spotifyConfig: SpotifyConfigurate
    var webVC: UIViewController?
    weak var delegate: SpotifyAuthWithWebDelegate?
    var tag: String {
        return "Web"
    }
    
    func initiateSession(_ viewController: UIViewController? = nil) -> Bool {
        guard let redirect_uri = spotifyConfig.redirectURI.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return false
        }
        guard let scope = spotifyConfig.requestedScopesString.joined(separator: " ").addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return false
        }
        guard let presentedVC = viewController else {
            logger.error("initiateSession presentedVC notfound")
            return false
        }
        guard let url = URL(string: "https://accounts.spotify.com/authorize?client_id=\(spotifyConfig.clientID)&response_type=code&redirect_uri=\(redirect_uri)&scope=\(scope)&show_dialog=true") else {
            return false
        }
        // TOOD: presenting Auth Web
        let web = authViewControllerWithURL(url: url)
        presentedVC.present(web, animated: true, completion: nil)
        webVC = web
        return true
    }
    
    // MARK:  - Spotify 网页授权
    func authViewControllerWithURL(url:URL) -> UIViewController {
        let safari = SFSafariViewController(url: url)
//        safari.delegate = self
        safari.modalPresentationStyle = .pageSheet
        return safari
    }
    
    func renewSession(refreshToken: String?) -> Bool {
        guard let token = refreshToken else {
            return false
        }
        do {
            try self.requestRenewToken(refreshToken: token)
            return true
        } catch {
            logger.error("\(error.localizedDescription)")
            return false
        }
    }
    
    func application(app: UIApplication, url: URL, options: [UIApplication.OpenURLOptionsKey : Any]) -> Bool {
        // 获取 code 去 swap accessToken
        guard url.absoluteString.contains(spotifyConfig.redirectURI), let query = url.query else {
            return false
        }
        self.requestSwapToken(code: nil, queryCode: query) { [weak self] in
            DispatchQueue.main.async {
                self?.webVC?.dismiss(animated: true, completion: nil)
            }
        }
        return true
    }
    
    func unlink() {
        
    }
    
    enum SpotifyError: Error {
        case SessionNotFound
        case URLFail
        case DataReadFail
        case DataDecodeFail
    }
    
    struct SpotifyAuthResponse: Codable {
        let access_token: String?
        let token_type: String?
        let scope: String?
        let expires_in: Int?
        let refresh_token: String?
        let error: String?
    }
    
    
    ///使用 Code 获取新的 AccessToken、RefreshToken
    @discardableResult
    func requestSwapToken(code: String?, queryCode: String?, complete: @escaping () -> Void) -> URLSessionDataTask {
        guard let url = URL(string: spotifyConfig.swapURLTest) else {
            fatalError(SpotifyError.SessionNotFound.localizedDescription)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = queryCode ?? "code=\(code ?? "")"
        request.httpBody = postString.data(using: .utf8)
        
        return self.postFormData(response: SpotifyAuthResponse.self, request: request) {
            [weak self]
            (auth) in
            complete()
            guard let auth = auth else {
                self?.delegate?.spotifyDidAuth(token: nil)
                return
            }
            guard let accessToken = auth.access_token,
                let refreshToken = auth.refresh_token,
                let expiresIn = auth.expires_in else {
                    let model = SpotifyToken(error: auth.error)
                    self?.delegate?.spotifyDidAuth(token: model)
                    return
            }
            let model = SpotifyToken(accessToken: accessToken, refreshToken: refreshToken, expiresIn: TimeInterval(expiresIn), expirationDate: nil)
            self?.delegate?.spotifyDidAuth(token: model)
        }
    }
    
    ///使用 RefreshToken 刷新 AccessToken
    @discardableResult
    func requestRenewToken(refreshToken: String) throws -> URLSessionDataTask {
        guard let url = URL(string: spotifyConfig.refreshURLTest) else {
            throw SpotifyError.URLFail
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        let postString = "refresh_token=\(refreshToken)"
        request.httpBody = postString.data(using: .utf8)

        return self.postFormData(response: SpotifyAuthResponse.self, request: request) {
            [weak self]
            (auth) in
            let refreshToken = auth?.refresh_token ?? refreshToken
            guard let at = auth?.access_token,
                let ex = auth?.expires_in else {
                    let model = SpotifyToken(error: auth?.error)
                    self?.delegate?.spotifyDidAuth(token: model)
                    return
            }
            let newModel = SpotifyToken(accessToken: at, refreshToken: refreshToken, expiresIn: TimeInterval(ex), expirationDate: nil)
            self?.delegate?.spotifyDidAuth(token: newModel)
        }
    }
    
    private func postFormData<T>(response: T.Type, request: URLRequest, complete: @escaping (T?) -> Void) -> URLSessionDataTask where T: Decodable {
        let task = URLSession.shared.dataTask(with: request) { (data, res, error) in
            if let error = error {
                logger.error("\(error.localizedDescription)")
                complete(nil)
                return
            }
            guard let data = data else {
                logger.error("\(SpotifyError.DataReadFail)")
                complete(nil)
                return
            }
            let decoder = JSONDecoder()
            // TODO: - https://medium.com/%E5%BD%BC%E5%BE%97%E6%BD%98%E7%9A%84-swift-ios-app-%E9%96%8B%E7%99%BC%E5%95%8F%E9%A1%8C%E8%A7%A3%E7%AD%94%E9%9B%86/jsondecoder-%E8%A7%A3%E6%9E%90%E6%99%82%E9%96%93%E7%9A%84-datedecodingstrategy-a4095481f193
            decoder.dateDecodingStrategy = .iso8601
            
            guard let object = try? decoder.decode(T.self, from: data) else {
                logger.error("\(SpotifyError.DataDecodeFail)")
                complete(nil)
                return
            }
            complete(object)
        }
        task.resume()
        return task
    }

}
