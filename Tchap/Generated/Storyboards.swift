// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

// swiftlint:disable sorted_imports
import Foundation
import UIKit

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

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
  internal enum DeviceVerificationDataLoadingViewController: StoryboardType {
    internal static let storyboardName = "DeviceVerificationDataLoadingViewController"

    internal static let initialScene = InitialSceneType<Tchap.DeviceVerificationDataLoadingViewController>(storyboard: DeviceVerificationDataLoadingViewController.self)
  }
  internal enum DeviceVerificationIncomingViewController: StoryboardType {
    internal static let storyboardName = "DeviceVerificationIncomingViewController"

    internal static let initialScene = InitialSceneType<Tchap.DeviceVerificationIncomingViewController>(storyboard: DeviceVerificationIncomingViewController.self)
  }
  internal enum DeviceVerificationStartViewController: StoryboardType {
    internal static let storyboardName = "DeviceVerificationStartViewController"

    internal static let initialScene = InitialSceneType<Tchap.DeviceVerificationStartViewController>(storyboard: DeviceVerificationStartViewController.self)
  }
  internal enum DeviceVerificationVerifiedViewController: StoryboardType {
    internal static let storyboardName = "DeviceVerificationVerifiedViewController"

    internal static let initialScene = InitialSceneType<Tchap.DeviceVerificationVerifiedViewController>(storyboard: DeviceVerificationVerifiedViewController.self)
  }
  internal enum DeviceVerificationVerifyViewController: StoryboardType {
    internal static let storyboardName = "DeviceVerificationVerifyViewController"

    internal static let initialScene = InitialSceneType<Tchap.DeviceVerificationVerifyViewController>(storyboard: DeviceVerificationVerifyViewController.self)
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
  internal enum RegistrationEmailSentViewController: StoryboardType {
    internal static let storyboardName = "RegistrationEmailSentViewController"

    internal static let initialScene = InitialSceneType<Tchap.RegistrationEmailSentViewController>(storyboard: RegistrationEmailSentViewController.self)
  }
  internal enum RegistrationFormViewController: StoryboardType {
    internal static let storyboardName = "RegistrationFormViewController"

    internal static let initialScene = InitialSceneType<Tchap.RegistrationFormViewController>(storyboard: RegistrationFormViewController.self)
  }
  internal enum RoomCreationViewController: StoryboardType {
    internal static let storyboardName = "RoomCreationViewController"

    internal static let initialScene = InitialSceneType<Tchap.RoomCreationViewController>(storyboard: RoomCreationViewController.self)
  }
  internal enum ServiceTermsModalScreenViewController: StoryboardType {
    internal static let storyboardName = "ServiceTermsModalScreenViewController"

    internal static let initialScene = InitialSceneType<Tchap.ServiceTermsModalScreenViewController>(storyboard: ServiceTermsModalScreenViewController.self)
  }
  internal enum WelcomeViewController: StoryboardType {
    internal static let storyboardName = "WelcomeViewController"

    internal static let initialScene = InitialSceneType<Tchap.WelcomeViewController>(storyboard: WelcomeViewController.self)
  }
  internal enum WidgetPermissionViewController: StoryboardType {
    internal static let storyboardName = "WidgetPermissionViewController"

    internal static let initialScene = InitialSceneType<Tchap.WidgetPermissionViewController>(storyboard: WidgetPermissionViewController.self)
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
    return UIStoryboard(name: name, bundle: Bundle(for: BundleToken.self))
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
}

internal struct InitialSceneType<T: UIViewController> {
  internal let storyboard: StoryboardType.Type

  internal func instantiate() -> T {
    guard let controller = storyboard.storyboard.instantiateInitialViewController() as? T else {
      fatalError("ViewController is not of the expected class \(T.self).")
    }
    return controller
  }
}

private final class BundleToken {}
