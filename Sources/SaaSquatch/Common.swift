import Foundation
import SwiftyJSON

extension String {
  var isBlank: Bool {
    return allSatisfy({ $0.isWhitespace })
  }
}

public enum BuilderError: Error {
    case invalidParameter(param: String, reason: String)
    case incompleteBuilder(builder: String, reason: String)
}

extension BuilderError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidParameter(let param, let reason):
            return "Invalid builder parameter `\(param)`: \(reason)"
        case .incompleteBuilder(let builder, let reason):
            return "Incomplete builder `\(builder)`: \(reason)"
        }
    }
}

/**
 A small wrapper struct around a user ID and an account ID for uniquely identifying users in SaaSquatch.
 */
public struct UserIdInput: Encodable {
    public let accountId: String
    public let userId: String
    
    public init(accountId: String, userId: String) {
        self.accountId = accountId
        self.userId = userId
    }
}

/**
 Specify the type of a widget to render.
 */
public protocol WidgetType {
    var widgetType: String { get }
}

/**
 A global widget is not tied to a particular program.
 */
public struct GlobalWidgetType: WidgetType {
    public let globalWidgetKey: String
    
    public init(globalWidgetKey: String) {
        self.globalWidgetKey = globalWidgetKey
    }
    
    public var widgetType: String {
        // TODO: What should we do if addingPercentEncoding returns nil?
        let globalWidgetKey = globalWidgetKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        return "w/\(globalWidgetKey)"
    }}

/**
 A program widget is related to a particular program, and requires a `programId` and `programWidgetKey`.
 */
public struct ProgramWidgetType: WidgetType {
    public let programId: String
    public let programWidgetKey: String
    
    public init(programId: String, programWidgetKey: String) {
        self.programId = programId
        self.programWidgetKey = programWidgetKey
    }
      
    public var widgetType: String {
        // TODO: What should we do if addingPercentEncoding returns nil?
        let programId = programId.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let programWidgetKey = programWidgetKey.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        return "p/\(programId)/w/\(programWidgetKey)"
    }
}

// NOTE: Borrowed from https://github.com/auth0/JWTDecode.swift/blob/master/JWTDecode/JWTDecode.swift
func base64UrlDecode(_ value: String) -> Data? {
    var base64 = value
        .replacingOccurrences(of: "-", with: "+")
        .replacingOccurrences(of: "_", with: "/")
    let length = Double(base64.lengthOfBytes(using: String.Encoding.utf8))
    let requiredLength = 4 * ceil(length / 4.0)
    let paddingLength = requiredLength - length
    if paddingLength > 0 {
        let padding = "".padding(toLength: Int(paddingLength), withPad: "=", startingAt: 0)
        base64 += padding
    }
    return Data(base64Encoded: base64, options: .ignoreUnknownCharacters)
}

func getJwtPayload(_ jwt: String) throws -> JSON {
    let jwtParts = jwt.split(separator: ".", maxSplits: 4, omittingEmptySubsequences: true)
    if jwtParts.count != 3 {
        throw SaaSquatchClientError.badInput(reason: "Invalid JWT, not enough parts")
    }
    let payloadPart = String(jwtParts[1])
    print(payloadPart)
    guard let payloadBytes = base64UrlDecode(payloadPart) else {
        throw SaaSquatchClientError.badInput(reason: "Invalid JWT, couldn't extract payload bytes")
    }
    return try JSON(data: payloadBytes)
}
