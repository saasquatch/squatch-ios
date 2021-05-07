import SwiftyJSON

/**
 Provides all of the input parameters required to perform a widget upsert operation.
 */
public struct WidgetUpsertInput {
    public let userInput: JSON
    public let accountId: String
    public let userId: String
    public let userJwt: String
    public let widgetType: WidgetType?
    public let engagementMedium: String?
    
    public final class Builder {
        private var userInput: JSON?
        private var accountId: String?
        private var userId: String?
        private var userJwt: String?
        private var widgetType: WidgetType?
        private var engagementMedium: String = "MOBILE"
        
        public init() {}
        
        /**
         Set the user input. If you want to provide user input via the payload of a JWT, use `setUserInputWithUserJwt` instead.
         
         - Parameters:
            - userInput: The SaaSquatch user fields.

         - Throws: `BuilderError` if a user ID or account ID was not provided.

         - Returns: The builder.
        */
        @discardableResult
        public func setUserInput(_ userInput: JSON) throws -> Builder {
            guard let userId = userInput["id"].string,
                  let accountId = userInput["accountId"].string else {
                throw BuilderError.invalidParameter(param: "userInput", reason: "must include `id` and `accountId`")
            }

            self.userInput = userInput
            self.userId = userId
            self.accountId = accountId

            return self
        }
        
        /**
         Set the user input from a user JWT by extracting the user from the JWT payload.
         
         - Parameters:
            - userJwt: A valid user JWT.

         - Throws: `BuilderError` if the JWT is blank or a user ID or account ID was not provided in the JWT payload.

         - Returns: The builder.
        */
        @discardableResult
        public func setUserInputWithUserJwt(_ userJwt: String) throws -> Builder {
            if (userJwt.isBlank) {
                throw BuilderError.invalidParameter(param: "userJwt", reason: "cannot be blank")
            }
            let payload = try getJwtPayload(userJwt)
            guard let userId = payload["user"]["id"].string,
                  let accountId = payload["user"]["accountId"].string else {
                throw BuilderError.invalidParameter(param: "userJwt", reason: "userJwt payload should include `user` with `user.id` and `user.accountId`")
            }
            self.userInput = payload["user"]
            self.userId = userId
            self.accountId = accountId
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
        public func setWidgetType(_ widgetType: WidgetType) -> Builder {
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
         Build a new `WidgetUpsertInput`.

         Throws: `BuilderError` if the builder is invalid..

         Returns: A `WidgetUpsertInput` object built from the builder options.
        */
        public func build() throws -> WidgetUpsertInput {
            guard let userInput = userInput,
                  let userId = userId,
                  let accountId = accountId else {
                throw BuilderError.incompleteBuilder(builder: "WidgetUpsertInput", reason: "must call setUserInput or setUserInputWithUserJwt")
            }
            
            guard let userJwt = userJwt else {
                throw BuilderError.incompleteBuilder(builder: "WidgetUpsertInput", reason: "must call setUserJwt or setUserInputWithUserJwt")
            }
            
            return WidgetUpsertInput(userInput: userInput, accountId: accountId, userId: userId, userJwt: userJwt, widgetType: widgetType, engagementMedium: engagementMedium)
        }
    }
}
