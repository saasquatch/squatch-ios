import SwiftyJSON

public enum GraphQLInputError: Error {
    case invalidQuery(_ reason: String)
    case invalidOperationName(_ reason: String)
}

extension GraphQLInputError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidQuery(let reason):
            return "Invalid query: \(reason)"
        case .invalidOperationName(let reason):
            return "Invalid operationname: \(reason)"
        }
    }
}

public struct GraphQLInput : Encodable {
    public let query: String
    public let operationName: String?
    public let variables: JSON?
    
    private init(query: String, operationName: String?, variables: JSON?) {
        self.query = query
        self.operationName = operationName
        self.variables = variables
    }
    
    final class Builder {
        private var query: String = ""
        private var operationName: String? = nil
        private var variables: JSON? = nil
        
        @discardableResult
        func withQuery(_ query: String) throws -> Builder {
            if (query.isBlank) {
                throw GraphQLInputError.invalidQuery("cannot be blank")
            }
            self.query = query
            return self
        }
        
        @discardableResult
        func withOperatioName(_ operationName: String) throws -> Builder {
            if (operationName.isBlank) {
                throw GraphQLInputError.invalidOperationName("cannot be blank")
            }
            self.operationName = operationName
            return self
        }
        
        @discardableResult
        func withVariables(_ variables: JSON) -> Builder {
            self.variables = variables
            return self
        }
        
        func build() throws -> GraphQLInput {
            if (query.isBlank) {
                throw GraphQLInputError.invalidQuery("cannot be blank")
            }
            return GraphQLInput(query: self.query, operationName: self.operationName, variables: self.variables)
        }
    }
}
