/**
 Provides configuration for a `SaaSquatchClient` using a Builder pattern.
 */
public struct ClientOptions {
    private static var DEFAULT_APP_DOMAIN = "app.referralsaasquatch.com"
    
    public let tenantAlias: String
    public let appDomain: String
    
    public class Builder {
        private var tenantAlias: String?
        private var appDomain: String = DEFAULT_APP_DOMAIN
        
        public init() {}

        /**
         Set the tenant alias.

         - Parameters:
            - tenantAlias: The desired tenant alias.

         - Throws: `BuilderError` if `tenantAlias` is an empty string.

         - Returns: The builder.
        */        
        @discardableResult
        public func setTenantAlias(_ tenantAlias: String) throws -> Builder {
            if tenantAlias.isBlank {
                throw BuilderError.invalidParameter(param: "tenantAlias", reason: "cannot be blank")
            }
            self.tenantAlias = tenantAlias
            return self
        }
        
        /**
         Sets the app domain. If unset the default app domain is app.referralsaasquatch.com.

         - Parameters:
            - appDomain: The domain from where to fetch SaaSquatch data from.

         - Throws: `BuilderError` if `appDomain` is an empty string.

         - Returns: The builder.
        */ 
        @discardableResult
        public func setAppDomain(_ appDomain: String) throws -> Builder {
            if appDomain.isBlank {
                throw BuilderError.invalidParameter(param: "appDomain", reason: "cannot be blank")
            }
            if appDomain.contains("://") {
                throw BuilderError.invalidParameter(param: "appDomain", reason: "should not have a protocol")
            }
            if appDomain.starts(with: "/") || appDomain.hasSuffix("/") {
                throw BuilderError.invalidParameter(param: "appDomain", reason: "should not start or end with a slash")
            }
            self.appDomain = appDomain
            return self
        }
        
        /**
         Build a new `ClientOptions`.

         Throws: `BuilderError`if the builder is invalid..

         Returns: A `ClientOptions` object built from the builder options.
        */
        public func build() throws -> ClientOptions {
            guard let tenantAlias = tenantAlias else {
                throw BuilderError.incompleteBuilder(builder: "ClientOptions", reason: "must call setTenantAlias")
            }
            return ClientOptions(tenantAlias: tenantAlias, appDomain: self.appDomain)
        }
    }
}
