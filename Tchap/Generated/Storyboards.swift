// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

// swiftlint:disable sorted_imports
import Foundation
import UIKit

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length implicit_return

// MARK: - Storyboard Scenes

// swiftlint:disable explicit_type_interface identifier_name line_length type_body_length type_name
internal enum StoryboardScene {
  internal enum AppVersionUpdateViewController: StoryboardType {
    internal static let storyboardName = "AppVersionUpdateViewController"

    internal static let initialScene = InitialSceneType<Tchap.AppVersionUpdateViewController>(storyboard: AppVersionUpdateViewController.self)
  }
  internal enum AuthenticationViewController: StoryboardType {
    internal static let storyboardName = "AuthenticationViewController"

    internal static let initialScene = InitialSceneType<Tchap.AuthenticationViewController>(storyboard: AuthenticationViewController.self)
  }
  internal enum ChangePasswordCurrentPasswordViewController: StoryboardType {
    internal static let storyboardName = "ChangePasswordCurrentPasswordViewController"

    internal static let initialScene = InitialSceneType<Tchap.ChangePasswordCurrentPasswordViewController>(storyboard: ChangePasswordCurrentPasswordViewController.self)
  }
  internal enum ChangePasswordNewPasswordViewController: StoryboardType {
    internal static let storyboardName = "ChangePasswordNewPasswordViewController"

    internal static let initialScene = InitialSceneType<Tchap.ChangePasswordNewPasswordViewController>(storyboard: ChangePasswordNewPasswordViewController.self)
  }
  internal enum EditHistoryViewController: StoryboardType {
    internal static let storyboardName = "EditHistoryViewController"

    internal static let initialScene = InitialSceneType<Tchap.EditHistoryViewController>(storyboard: EditHistoryViewController.self)
  }
  internal enum EmojiPickerViewController: StoryboardType {
    internal static let storyboardName = "EmojiPickerViewController"

    internal static let initialScene = InitialSceneType<Tchap.EmojiPickerViewController>(storyboard: EmojiPickerViewController.self)
  }
  internal enum FavouriteMessagesViewController: StoryboardType {
    internal static let storyboardName = "FavouriteMessagesViewController"

    internal static let initialScene = InitialSceneType<Tchap.FavouriteMessagesViewController>(storyboard: FavouriteMessagesViewController.self)
  }
  internal enum ForgotPasswordCheckedEmailViewController: StoryboardType {
    internal static let storyboardName = "ForgotPasswordCheckedEmailViewController"

    internal static let initialScene = InitialSceneType<Tchap.ForgotPasswordCheckedEmailViewController>(storyboard: ForgotPasswordCheckedEmailViewController.self)
  }
  internal enum ForgotPasswordFormViewController: StoryboardType {
    internal static let storyboardName = "ForgotPasswordFormViewController"

    internal static let initialScene = InitialSceneType<Tchap.ForgotPasswordFormViewController>(storyboard: ForgotPasswordFormViewController.self)
  }
  internal enum ForgotPasswordVerifyEmailViewController: StoryboardType {
    internal static let storyboardName = "ForgotPasswordVerifyEmailViewController"

    internal static let initialScene = InitialSceneType<Tchap.ForgotPasswordVerifyEmailViewController>(storyboard: ForgotPasswordVerifyEmailViewController.self)
  }
  internal enum HomeViewController: StoryboardType {
    internal static let storyboardName = "HomeViewController"

    internal static let initialScene = InitialSceneType<Tchap.HomeViewController>(storyboard: HomeViewController.self)
  }
  internal enum PublicRoomsViewController: StoryboardType {
    internal static let storyboardName = "PublicRoomsViewController"

    internal static let initialScene = InitialSceneType<Tchap.PublicRoomsViewController>(storyboard: PublicRoomsViewController.self)
  }
  internal enum ReactionHistoryViewController: StoryboardType {
    internal static let storyboardName = "ReactionHistoryViewController"

    internal static let initialScene = InitialSceneType<Tchap.ReactionHistoryViewController>(storyboard: ReactionHistoryViewController.self)
  }
  internal enum RegistrationEmailSentViewController: StoryboardType {
    internal static let storyboardName = "RegistrationEmailSentViewController"

    internal static let initialScene = InitialSceneType<Tchap.RegistrationEmailSentViewController>(storyboard: RegistrationEmailSentViewController.self)
  }
  internal enum RegistrationFormViewController: StoryboardType {
    internal static let storyboardName = "RegistrationFormViewController"

    internal static let initialScene = InitialSceneType<Tchap.RegistrationFormViewController>(storyboard: RegistrationFormViewController.self)
  }
  internal enum RoomAccessByLinkViewController: StoryboardType {
    internal static let storyboardName = "RoomAccessByLinkViewController"

    internal static let initialScene = InitialSceneType<Tchap.RoomAccessByLinkViewController>(storyboard: RoomAccessByLinkViewController.self)
  }
  internal enum RoomContextualMenuViewController: StoryboardType {
    internal static let storyboardName = "RoomContextualMenuViewController"

    internal static let initialScene = InitialSceneType<Tchap.RoomContextualMenuViewController>(storyboard: RoomContextualMenuViewController.self)
  }
  internal enum RoomCreationViewController: StoryboardType {
    internal static let storyboardName = "RoomCreationViewController"

    internal static let initialScene = InitialSceneType<Tchap.RoomCreationViewController>(storyboard: RoomCreationViewController.self)
  }
  internal enum WelcomeViewController: StoryboardType {
    internal static let storyboardName = "WelcomeViewController"

    internal static let initialScene = InitialSceneType<Tchap.WelcomeViewController>(storyboard: WelcomeViewController.self)
  }
}
// swiftlint:enable explicit_type_interface identifier_name line_length type_body_length type_name

// MARK: - Implementation Details

internal protocol StoryboardType {
  static var storyboardName: String { get }
}

internal extension StoryboardType {
  static var storyboard: UIStoryboard {
    let name = self.storyboardName
    return UIStoryboard(name: name, bundle: BundleToken.bundle)
  }
}

internal struct SceneType<T: UIViewController> {
  internal let storyboard: StoryboardType.Type
  internal let identifier: String

  internal func instantiate() -> T {
    let identifier = self.identifier
    guard let controller = storyboard.storyboard.instantiateViewController(withIdentifier: identifier) as? T else {
      fatalError("ViewController '\(identifier)' is not of the expected class \(T.self).")
    }
    return controller
  }

  @available(iOS 13.0, tvOS 13.0, *)
  internal func instantiate(creator block: @escaping (NSCoder) -> T?) -> T {
    return storyboard.storyboard.instantiateViewController(identifier: identifier, creator: block)
  }
}

internal struct InitialSceneType<T: UIViewController> {
  internal let storyboard: StoryboardType.Type

  internal func instantiate() -> T {
    guard let controller = storyboard.storyboard.instantiateInitialViewController() as? T else {
      fatalError("ViewController is not of the expected class \(T.self).")
    }
    return controller
  }

  @available(iOS 13.0, tvOS 13.0, *)
  internal func instantiate(creator block: @escaping (NSCoder) -> T?) -> T {
    guard let controller = storyboard.storyboard.instantiateInitialViewController(creator: block) else {
      fatalError("Storyboard \(storyboard.storyboardName) does not have an initial scene.")
    }
    return controller
  }
}

// swiftlint:disable convenience_type
private final class BundleToken {
  static let bundle: Bundle = {
    #if SWIFT_PACKAGE
    return Bundle.module
    #else
    return Bundle(for: BundleToken.self)
    #endif
  }()
}
// swiftlint:enable convenience_type
