/**
 Provides all of the input parameters required to perform a render widget operation.
 */
public struct RenderWidgetInput {
    public let user: UserIdInput?
    public let userJwt: String?
    public let widgetType: WidgetType?
    public let engagementMedium: String
    public let locale: String
    
    public final class Builder {
        private var user: UserIdInput?
        private var userJwt: String?
        private var widgetType: WidgetType?
        private var engagementMedium: String = "MOBILE"
        private var locale: String?
        
        public init() {}
        
        /**
         Set the user.
         
         - Parameters:
            - user: The SaaSquatch user.

         - Returns: The builder.
        */
        @discardableResult
        public func setUser(_ user: UserIdInput) throws -> Builder {
            self.user = user
            return self
        }
        
        /**
         Set the user from a user JWT by extracting the user from the JWT payload.
         
         - Parameters:
            - userJwt: A valid user JWT.

         - Throws: `BuilderError` if the JWT is blank or a user ID or account ID was not provided in the JWT payload.

         - Returns: The builder.
        */
        @discardableResult
        func setUserFromJwt(_ userJwt: String) throws -> Builder {
            if (userJwt.isBlank) {
                throw BuilderError.invalidParameter(param: "userJwt", reason: "cannot be blank")
            }
            let payload = try getJwtPayload(userJwt)
            guard let userId = payload["user"]["id"].string,
               let accountId = payload["user"]["accountId"].string else {
                throw BuilderError.invalidParameter(param: "userJwt", reason: "userJwt payload should include `user.id` and `user.accountId`")
            }
            self.user = UserIdInput(accountId: accountId, userId: userId)
            self.userJwt = userJwt
            return self
        }
        
        /**
         Set user JWT.
         
         - Parameters:
            - userJwt: A valid user JWT.

         - Throws: `BuilderError` if the JWT is blank.

         - Returns: The builder.
        */
        @discardableResult
        public func setUserJwt(_ userJwt: String) throws -> Builder {
            if userJwt.isBlank {
                throw BuilderError.invalidParameter(param: "userJwt", reason: "cannot be blank")
            }
            self.userJwt = userJwt
            return self
        }
        
        /**
         Set the widget type.
         
         - Parameters:
            - widgetType: The widget type.

         - Returns: The builder.
        */
        @discardableResult
        public func setWidgetType(_ widgetType: WidgetType) throws -> Builder {
            self.widgetType = widgetType
            return self
        }
        
        /**
         Set the engagement medium. By defaul it is "MOBILE".
         
         - Parameters:
            - engemangeMedium: The engagement medium.

         - Returns: The builder.
        */
        @discardableResult
        public func setEngagementMedium(_ engagementMedium: String) throws -> Builder {
            if engagementMedium.isBlank {
                throw BuilderError.invalidParameter(param: "engagementMedium", reason: "cannot be blank")
            }
            self.engagementMedium = engagementMedium
            return self
        }
        
        /**
         Set the locale for rendering the widget.
         
         - Parameters:
            - locale: The locale.

         - Returns: The builder.
        */
        @discardableResult
        public func setLocale(_ locale: String) throws -> Builder {
            if locale.isBlank {
                throw BuilderError.invalidParameter(param: "locale", reason: "cannot be blank")
            }
            self.locale = locale
            return self
        }
        
        /**
         Build a new `RenderWidgetInput`.

         Throws: `BuilderError` if the builder is invalid..

         Returns: A `RenderWidgetInput` object built from the builder options.
        */
        public func build() throws -> RenderWidgetInput {
            guard let locale = locale else {
                throw BuilderError.incompleteBuilder(builder: "RenderWidgetInput", reason: "must call setLocale")
            }
            
            return RenderWidgetInput(user: user, userJwt: userJwt, widgetType: widgetType, engagementMedium: engagementMedium, locale: locale)
        }
        
    }
}
