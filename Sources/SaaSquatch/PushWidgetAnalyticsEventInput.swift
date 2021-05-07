public struct PushWidgetAnalyticsEventInput {
    public let user: UserIdInput
    public let userJwt: String
    public let programId: String?
    public let engagementMedium: String?
    public let shareMedium: String?
    
    public final class Builder {
        private var user: UserIdInput?
        private var userJwt: String?
        private var programId: String?
        private var engagementMedium: String = "MOBILE"
        private var shareMedium: String?
        
        public init() {}
        
        @discardableResult
        public func setUser(_ user: UserIdInput) throws -> Builder {
            self.user = user
            return self
        }
        
        @discardableResult
        public func setUserJwt(_ userJwt: String) throws -> Builder {
            if userJwt.isBlank {
                throw BuilderError.invalidParameter(param: "userJwt", reason: "cannot be blank")
            }
            self.userJwt = userJwt
            return self
        }
        
        @discardableResult
        public func setProgramId(_ programId: String) throws -> Builder {
            if programId.isBlank {
                throw BuilderError.invalidParameter(param: "programId", reason: "cannot be blank")
            }
            self.programId = programId
            return self
        }
        
        @discardableResult
        public func setEngagementMedium(_ engagementMedium: String) throws -> Builder {
            if engagementMedium.isBlank {
                throw BuilderError.invalidParameter(param: "engagementMedium", reason: "cannot be blank")
            }
            self.engagementMedium = engagementMedium
            return self
        }
        
        @discardableResult
        public func setShareMedium(_ shareMedium: String) throws -> Builder {
            if shareMedium.isBlank {
                throw BuilderError.invalidParameter(param: "shareMedium", reason: "cannot be blank")
            }
            self.shareMedium = shareMedium
            return self
        }
        
        public func build() throws -> PushWidgetAnalyticsEventInput {
            guard let user = user else {
                throw BuilderError.incompleteBuilder(builder: "PushWidgetAnalyticsEventInput", reason: "must call setUser")
            }
            
            guard let userJwt = userJwt else {
                throw BuilderError.incompleteBuilder(builder: "PushWidgetAnalyticsEventInput", reason: "must call setUserJwt")
            }
            
            return PushWidgetAnalyticsEventInput(user: user, userJwt: userJwt, programId: programId, engagementMedium: engagementMedium, shareMedium: shareMedium)
        }
    }
}
