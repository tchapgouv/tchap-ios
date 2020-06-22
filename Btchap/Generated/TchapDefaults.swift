// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Plist Files

// swiftlint:disable identifier_name line_length type_body_length
internal enum TchapDefaults {
  private static let _document = PlistDocument(path: "Btchap-Defaults.plist")

  internal static let appGroupId: String = _document["appGroupId"]
  internal static let appLanguage: String = _document["appLanguage"]
  internal static let bugReportApp: String = _document["bugReportApp"]
  internal static let bugReportDefaultHost: String = _document["bugReportDefaultHost"]
  internal static let bugReportEndpointUrlSuffix: String = _document["bugReportEndpointUrlSuffix"]
  internal static let clientConfigURL: String = _document["clientConfigURL"]
  internal static let createConferenceCallsWithJitsi: Bool = _document["createConferenceCallsWithJitsi"]
  internal static let enableRageShake: Bool = _document["enableRageShake"]
  internal static let integrationsRestUrl: String = _document["integrationsRestUrl"]
  internal static let integrationsUiUrl: String = _document["integrationsUiUrl"]
  internal static let matrixApps: Bool = _document["matrixApps"]
  internal static let maxAllowedMediaCacheSize: Int = _document["maxAllowedMediaCacheSize"]
  internal static let otherIdentityServerNames: [String] = _document["otherIdentityServerNames"]
  internal static let preferredIdentityServerNames: [String] = _document["preferredIdentityServerNames"]
  internal static let pushGatewayURL: String = _document["pushGatewayURL"]
  internal static let pushKitAppIdDev: String = _document["pushKitAppIdDev"]
  internal static let pushKitAppIdProd: String = _document["pushKitAppIdProd"]
  internal static let pusherAppIdDev: String = _document["pusherAppIdDev"]
  internal static let pusherAppIdProd: String = _document["pusherAppIdProd"]
  internal static let roomDirectoryServers: [String] = _document["roomDirectoryServers"]
  internal static let serverUrlPrefix: String = _document["serverUrlPrefix"]
  internal static let showAllEventsInRoomHistory: Bool = _document["showAllEventsInRoomHistory"]
  internal static let showLeftMembersInRoomMemberList: Bool = _document["showLeftMembersInRoomMemberList"]
  internal static let showRedactionsInRoomHistory: Bool = _document["showRedactionsInRoomHistory"]
  internal static let showUnsupportedEventsInRoomHistory: Bool = _document["showUnsupportedEventsInRoomHistory"]
  internal static let sortRoomMembersUsingLastSeenTime: Bool = _document["sortRoomMembersUsingLastSeenTime"]
  internal static let syncLocalContacts: Bool = _document["syncLocalContacts"]
  internal static let tacURL: String = _document["tacURL"]
  internal static let webAppUrl: String = _document["webAppUrl"]
  internal static let webAppUrlBeta: String = _document["webAppUrlBeta"]
  internal static let webAppUrlDev: String = _document["webAppUrlDev"]
}
// swiftlint:enable identifier_name line_length type_body_length

// MARK: - Implementation Details

private func arrayFromPlist<T>(at path: String) -> [T] {
  let bundle = Bundle(for: BundleToken.self)
  guard let url = bundle.url(forResource: path, withExtension: nil),
    let data = NSArray(contentsOf: url) as? [T] else {
    fatalError("Unable to load PLIST at path: \(path)")
  }
  return data
}

private struct PlistDocument {
  let data: [String: Any]

  init(path: String) {
    let bundle = Bundle(for: BundleToken.self)
    guard let url = bundle.url(forResource: path, withExtension: nil),
      let data = NSDictionary(contentsOf: url) as? [String: Any] else {
        fatalError("Unable to load PLIST at path: \(path)")
    }
    self.data = data
  }

  subscript<T>(key: String) -> T {
    guard let result = data[key] as? T else {
      fatalError("Property '\(key)' is not of type \(T.self)")
    }
    return result
  }
}

private final class BundleToken {}
