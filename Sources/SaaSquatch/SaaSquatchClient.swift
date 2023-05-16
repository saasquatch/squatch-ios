import Foundation
import SwiftyJSON

public enum SaaSquatchClientError: Error {
    case invalidUrl
    case clientError(error: Error)
    case serverError(response: URLResponse?)
    case badInput(reason: String)
    case badResponse
    case apiError(errors: [JSON])
}

extension SaaSquatchClientError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidUrl:
            return "Invalid url, check tenant alias"
        case .clientError(let error):
            return "Client error: \(error)"
        case .serverError(let response):
            return "Server error: \(String(describing: response))"
        case .badInput(let reason):
            return "Bad input: \(reason)"
        case .badResponse:
            return "Bad response from server"
        case .apiError(let errors):
            return "API error: \(String(describing: errors))"
        }
    }
}

public typealias ResultHandler<T> = (_ result: Result<T, SaaSquatchClientError>) -> Void

/**
 A client for communicating with the SaaSquatch API.
 */
public final class SaaSquatchClient {
    private final var clientOptions: ClientOptions
    
    public init(_ clientOptions: ClientOptions) {
        self.clientOptions = clientOptions
    }
    
    /**
     Perform a GraphQL query.
     
     - Parameters:
        - input: The GraphQL query input.
        - userJwt: A valid user JWT.
        - completion: A completion callback for the response which receives the JSON body of a successful request..
     
     - Throws: `SaaSquatchClientError`if there is a failure making the request.
    */
    public func graphQL(input: GraphQLInput, userJwt: String?, completion: @escaping ResultHandler<JSON>) throws {
        let pathComponents = ["/api", "v1", self.clientOptions.tenantAlias, "graphql"]
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = self.clientOptions.appDomain
        urlComponents.path = pathComponents.joined(separator: "/")
        
        if let url = urlComponents.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try JSONEncoder().encode(input)
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            
            if userJwt != nil {
                request.addValue("Bearer \(userJwt!)", forHTTPHeaderField: "Authorization")
            }
            
            executeRequest(request) { (result: Result<JSON, SaaSquatchClientError>) in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                case .success(let json):
                    if let errors = json["errors"].array {
                        completion(.failure(SaaSquatchClientError.apiError(errors: errors)))
                        return
                    }
                    completion(.success(json))
                }
            }
        } else {
            throw SaaSquatchClientError.invalidUrl
        }
    }
    
    /**
     Perform a render widget operation.
     
     - Parameters:
        - input: The render widget input.
        - completion: A completion callback for the response that receives the rendered HTML for the widget.
     
     - Throws: `SaaSquatchClientError`if there is a failure making the request.
    */
    public func renderWidget(_ input: RenderWidgetInput, completion: @escaping ResultHandler<String>) throws {
        var variables: JSON = [
            "engagementMedium": input.engagementMedium,
            "locale": input.locale,
        ]
        if let user = input.user {
            variables["user"] = ["id": user.userId, "accountId": user.accountId ]
        }
        if let widgetType = input.widgetType {
            variables["widgetType"].string = widgetType.widgetType
        }
        
        let queryInput = try GraphQLInput.Builder().withQuery(GraphQLQueries.RENDER_WIDGET).withVariables(variables).build()
        
        try graphQL(input: queryInput, userJwt: input.userJwt) { result in
            switch result {
            case .failure(let error):
                completion(.failure(error))
            case .success(let data):
                if let template = data["data"]["renderWidget"]["template"].string {
                    completion(.success(template))
                } else {
                    completion(.failure(SaaSquatchClientError.badResponse))
                }
            }
        }
    }
    
    /**
     Perform a user upsert operation.
     
     - Parameters:
        - userInput: The render widget input.
        - userJwt: A valid user JWT.
        - completion: A completion callback for the response that receives the JSON response of the request.
     
     - Throws: `SaaSquatchClientError`if there is a failure making the request.
    */
    public func userUpsert(userInput: JSON, userJwt: String, completion: @escaping ResultHandler<JSON>) throws {
        guard let userId = userInput["id"].string,
              let accountId = userInput["accountId"].string else {
            throw SaaSquatchClientError.badInput(reason: "`userInput` must include `id` and `accountId`")
        }
        if userJwt.isBlank {
            throw SaaSquatchClientError.badInput(reason: "`userJwt` cannot be blank")
        }
        return try userUpsertInternal(accountId: accountId, userId: userId, body: userInput, userJwt: userJwt, widgetType: nil, engagementMedium: nil, isWidgetRequest: false, completion: completion)
    }
    
    public func userUpsertWithUserJwt(_ userJwt: String, completion: @escaping ResultHandler<JSON>) throws {
        if userJwt.isBlank {
            throw SaaSquatchClientError.badInput(reason: "`userJwt` cannot be blank")
        }
        let payload = try getJwtPayload(userJwt)
        if !payload["user"].exists() {
            throw SaaSquatchClientError.badInput(reason: "`JWT payload must include `user`")
        }
        guard let userId = payload["user"]["id"].string,
              let accountId = payload["user"]["accountId"].string else {
            throw SaaSquatchClientError.badInput(reason: "`user` in JWT must include `id` and `accountId`")
        }
        try userUpsertInternal(accountId: accountId, userId: userId, body: payload["user"], userJwt: userJwt, widgetType: nil, engagementMedium: nil, isWidgetRequest: false, completion: completion)
    }
    
    /**
     Perform a widget upsert operation which upserts a user and renders their widget.
     
     - Parameters:
        - input: The widget upsert input.
        - completion: A completion callback for the response that receives the JSON response of the widget upsert, which contains the user and the rendered widget HTML.
     
     - Throws: `SaaSquatchClientError`if there is a failure making the request.
    */
    public func widgetUpsert(_ input: WidgetUpsertInput, completion: @escaping ResultHandler<JSON>) throws {
        try userUpsertInternal(accountId: input.accountId, userId: input.userId, body: input.userInput, userJwt: input.userJwt, widgetType: input.widgetType, engagementMedium: input.engagementMedium, isWidgetRequest: true, completion: completion)
    }
    
    private func userUpsertInternal(accountId: String, userId: String, body: JSON, userJwt: String, widgetType: WidgetType?, engagementMedium: String?, isWidgetRequest: Bool, completion: @escaping ResultHandler<JSON>) throws {
        var pathComponents = ["/api", "v1", self.clientOptions.tenantAlias]
        if isWidgetRequest {
            pathComponents.append("widget")
        } else {
            pathComponents.append("open")
        }
        pathComponents.append("account")
        pathComponents.append(accountId)
        pathComponents.append("user")
        pathComponents.append(userId)
        if isWidgetRequest {
            pathComponents.append("upsert")
        }
        
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = self.clientOptions.appDomain
        urlComponents.path = pathComponents.joined(separator: "/")
        
        var queryItems: [URLQueryItem] = []
        if let widgetType = widgetType {
            queryItems.append(URLQueryItem(name: "widgetType", value: widgetType.widgetType))
        }
        if let engagementMedium = engagementMedium {
            queryItems.append(URLQueryItem(name:"engagementMedium", value: engagementMedium))
        }
        urlComponents.queryItems = queryItems
        
        if let url = urlComponents.url {
            var request = URLRequest(url: url)
            request.httpMethod = "PUT"
            request.httpBody = try body.rawData()
            request.addValue("Bearer \(userJwt)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            executeRequest(request, completion: completion)
        } else {
            throw SaaSquatchClientError.invalidUrl
        }
    }
    
    /**
     Logs a user event.
     
     - Parameters:
        - userEventInput: Valid JSON for a user event.
        - userJwt: A valid user JWT.
        - completion: A completion callback for the response that receives the JSON response of the widget upsert.
     
     - Throws: `SaaSquatchClientError`if there is a failure making the request.
    */
    public func logUserEvent(userEventInput: JSON, userJwt: String, completion: @escaping ResultHandler<JSON>) throws {
        guard let userId = userEventInput["userId"].string,
              let accountId = userEventInput["accountId"].string else {
            throw SaaSquatchClientError.badInput(reason: "`userEventInput` must include `userId` and `accountId`")
        }
        if userJwt.isBlank {
            throw SaaSquatchClientError.badInput(reason: "`userJwt` cannot be blank")
        }
        
        let pathComponents = ["/api", "v1", self.clientOptions.tenantAlias, "open", "account", accountId, "user", userId, "events"]
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = self.clientOptions.appDomain
        urlComponents.path = pathComponents.joined(separator: "/")
        
        if let url = urlComponents.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = try userEventInput.rawData()
            request.addValue("Bearer \(userJwt)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            executeRequest(request, completion: completion)
        } else {
            throw SaaSquatchClientError.invalidUrl
        }
    }
    
    /**
     Push a widget loaded analytics event.
     
     - Parameters:
        - input: The widget analytics event input.
        - completion: A completion callback for the response that receives the JSON response of the request.
     
     - Throws: `SaaSquatchClientError`if there is a failure making the request.
    */
    public func pushWidgetLoadedAnalyticsEvent(_ input: PushWidgetAnalyticsEventInput, completion: @escaping ResultHandler<Void>) throws {
        try pushWidgetAnalyticsEvent(type: "loaded", input: input, completion: completion)
    }
    
    /**
     Push a widget shared analytics event.
     
     - Parameters:
        - input: The widget analytics event input.
        - completion: A completion callback for the response that receives the JSON response of the request.
     
     - Throws: `SaaSquatchClientError`if there is a failure making the request.
    */
    public func pushWidgetSharedAnalyticsEvent(_ input: PushWidgetAnalyticsEventInput, completion: @escaping ResultHandler<Void>) throws {
        try pushWidgetAnalyticsEvent(type: "shared", input: input, completion: completion)
    }
    
    private func pushWidgetAnalyticsEvent(type: String, input: PushWidgetAnalyticsEventInput, completion: @escaping ResultHandler<Void>) throws {
        let pathComponents = ["/a", self.clientOptions.tenantAlias, "widgets", "analytics", type]
        var urlComponents = URLComponents()
        urlComponents.scheme = "https"
        urlComponents.host = self.clientOptions.appDomain
        urlComponents.path = pathComponents.joined(separator: "/")
        
        var queryItems: [URLQueryItem] = []
        queryItems.append(URLQueryItem(name: "externalUserId", value: input.user.userId))
        queryItems.append(URLQueryItem(name: "externalAccountId", value: input.user.accountId))
        if let programId = input.programId {
            queryItems.append(URLQueryItem(name: "programId", value: programId))
        }
        if let engagementMedium = input.engagementMedium {
            queryItems.append(URLQueryItem(name: "engagementMedium", value: engagementMedium))
        }
        if let shareMedium = input.shareMedium {
            if type == "loaded" {
                throw SaaSquatchClientError.badInput(reason: "shareMedium cannot be set for `loaded` analytics event")
            }
            queryItems.append(URLQueryItem(name: "shareMedium", value: shareMedium))
        }
        urlComponents.queryItems = queryItems
        
        if let url = urlComponents.url {
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.httpBody = Data()
            request.addValue("Bearer \(input.userJwt)", forHTTPHeaderField: "Authorization")
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            executeRequest(request, completion: completion)
        } else {
            throw SaaSquatchClientError.invalidUrl
        }
    }
    
    private func executeRequest(_ request: URLRequest, completion: @escaping ResultHandler<Void>) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(SaaSquatchClientError.clientError(error: error)))
                return
            }
                        
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(SaaSquatchClientError.serverError(response: response)))
                return
            }
            
            completion(.success(()))
        }
        
        task.resume()
    }
    
    private func executeRequest(_ request: URLRequest, completion: @escaping ResultHandler<JSON>) {
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                completion(.failure(SaaSquatchClientError.clientError(error: error)))
                return
            }
                        
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                completion(.failure(SaaSquatchClientError.serverError(response: response)))
                return
            }
            
            guard let data = data,
                  let json = try? JSON(data: data) else {
                completion(.failure(SaaSquatchClientError.badResponse))
                return
            }
            
            completion(.success(json))
        }
        
        task.resume()
    }
}
