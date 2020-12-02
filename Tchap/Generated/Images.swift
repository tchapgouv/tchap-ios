// swiftlint:disable all
// Generated using SwiftGen — https://github.com/SwiftGen/SwiftGen

#if os(macOS)
  import AppKit
#elseif os(iOS)
  import UIKit
#elseif os(tvOS) || os(watchOS)
  import UIKit
#endif

// Deprecated typealiases
@available(*, deprecated, renamed: "ImageAsset.Image", message: "This typealias will be removed in SwiftGen 7.0")
internal typealias AssetImageTypeAlias = ImageAsset.Image

// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
internal enum Asset {
  internal enum Images {
    internal static let callAudioMuteOffIcon = ImageAsset(name: "call_audio_mute_off_icon")
    internal static let callAudioMuteOnIcon = ImageAsset(name: "call_audio_mute_on_icon")
    internal static let callChatIcon = ImageAsset(name: "call_chat_icon")
    internal static let callHangupIcon = ImageAsset(name: "call_hangup_icon")
    internal static let callSpeakerOffIcon = ImageAsset(name: "call_speaker_off_icon")
    internal static let callSpeakerOnIcon = ImageAsset(name: "call_speaker_on_icon")
    internal static let callVideoMuteOffIcon = ImageAsset(name: "call_video_mute_off_icon")
    internal static let callVideoMuteOnIcon = ImageAsset(name: "call_video_mute_on_icon")
    internal static let cameraSwitch = ImageAsset(name: "camera_switch")
    internal static let tchapIconCallkit = ImageAsset(name: "tchap_icon_callkit")
    internal static let adminIcon = ImageAsset(name: "admin_icon")
    internal static let backIcon = ImageAsset(name: "back_icon")
    internal static let chevron = ImageAsset(name: "chevron")
    internal static let closeButton = ImageAsset(name: "close_button")
    internal static let createRoom = ImageAsset(name: "create_room")
    internal static let disclosureIcon = ImageAsset(name: "disclosure_icon")
    internal static let group = ImageAsset(name: "group")
    internal static let monitor = ImageAsset(name: "monitor")
    internal static let placeholder = ImageAsset(name: "placeholder")
    internal static let plusIcon = ImageAsset(name: "plus_icon")
    internal static let removeIcon = ImageAsset(name: "remove_icon")
    internal static let selectionTick = ImageAsset(name: "selection_tick")
    internal static let selectionUntick = ImageAsset(name: "selection_untick")
    internal static let shrinkIcon = ImageAsset(name: "shrink_icon")
    internal static let smartphone = ImageAsset(name: "smartphone")
    internal static let startChat = ImageAsset(name: "start_chat")
    internal static let tchapIcAddBymail = ImageAsset(name: "tchap_ic_add_bymail")
    internal static let tchapIcAddContact = ImageAsset(name: "tchap_ic_add_contact")
    internal static let tchapIcInviteByLink = ImageAsset(name: "tchap_ic_invite_by_link")
    internal static let e2eBlocked = ImageAsset(name: "e2e_blocked")
    internal static let e2eUnencrypted = ImageAsset(name: "e2e_unencrypted")
    internal static let e2eWarning = ImageAsset(name: "e2e_warning")
    internal static let encryptionNormal = ImageAsset(name: "encryption_normal")
    internal static let encryptionTrusted = ImageAsset(name: "encryption_trusted")
    internal static let encryptionWarning = ImageAsset(name: "encryption_warning")
    internal static let leave = ImageAsset(name: "leave")
    internal static let notifications = ImageAsset(name: "notifications")
    internal static let notificationsOff = ImageAsset(name: "notificationsOff")
    internal static let pin = ImageAsset(name: "pin")
    internal static let unpin = ImageAsset(name: "unpin")
    internal static let closeBanner = ImageAsset(name: "close_banner")
    internal static let importFilesButton = ImageAsset(name: "import_files_button")
    internal static let keyBackupLogo = ImageAsset(name: "key_backup_logo")
    internal static let revealPasswordButton = ImageAsset(name: "reveal_password_button")
    internal static let launchScreen = ImageAsset(name: "LaunchScreen")
    internal static let cameraCapture = ImageAsset(name: "camera_capture")
    internal static let cameraPlay = ImageAsset(name: "camera_play")
    internal static let cameraStop = ImageAsset(name: "camera_stop")
    internal static let cameraVideoCapture = ImageAsset(name: "camera_video_capture")
    internal static let videoIcon = ImageAsset(name: "video_icon")
    internal static let error = ImageAsset(name: "error")
    internal static let newmessages = ImageAsset(name: "newmessages")
    internal static let scrolldown = ImageAsset(name: "scrolldown")
    internal static let scrollup = ImageAsset(name: "scrollup")
    internal static let typing = ImageAsset(name: "typing")
    internal static let attachmentScanStatusInProgress = ImageAsset(name: "attachment_scan_status_in_progress")
    internal static let attachmentScanStatusInfected = ImageAsset(name: "attachment_scan_status_infected")
    internal static let attachmentScanStatusUnavailable = ImageAsset(name: "attachment_scan_status_unavailable")
    internal static let roomContextMenuCopy = ImageAsset(name: "room_context_menu_copy")
    internal static let roomContextMenuEdit = ImageAsset(name: "room_context_menu_edit")
    internal static let roomContextMenuMore = ImageAsset(name: "room_context_menu_more")
    internal static let roomContextMenuRedact = ImageAsset(name: "room_context_menu_redact")
    internal static let roomContextMenuReply = ImageAsset(name: "room_context_menu_reply")
    internal static let sendIcon = ImageAsset(name: "send_icon")
    internal static let uploadIcon = ImageAsset(name: "upload_icon")
    internal static let voiceCallIcon = ImageAsset(name: "voice_call_icon")
    internal static let forumAvatarIconHr = ImageAsset(name: "forum_avatar_icon_hr")
    internal static let forumRoom = ImageAsset(name: "forum_room")
    internal static let privateAvatarIconHr = ImageAsset(name: "private_avatar_icon_hr")
    internal static let privateRoom = ImageAsset(name: "private_room")
    internal static let addParticipant = ImageAsset(name: "add_participant")
    internal static let appsIcon = ImageAsset(name: "apps-icon")
    internal static let editIcon = ImageAsset(name: "edit_icon")
    internal static let jumpToUnread = ImageAsset(name: "jump_to_unread")
    internal static let mainAliasIcon = ImageAsset(name: "main_alias_icon")
    internal static let modIcon = ImageAsset(name: "mod_icon")
    internal static let moreReactions = ImageAsset(name: "more_reactions")
    internal static let fileDocIcon = ImageAsset(name: "file_doc_icon")
    internal static let fileMusicIcon = ImageAsset(name: "file_music_icon")
    internal static let filePhotoIcon = ImageAsset(name: "file_photo_icon")
    internal static let fileVideoIcon = ImageAsset(name: "file_video_icon")
    internal static let searchIcon = ImageAsset(name: "search_icon")
    internal static let secretsRecoveryKey = ImageAsset(name: "secrets_recovery_key")
    internal static let secretsRecoveryPassphrase = ImageAsset(name: "secrets_recovery_passphrase")
    internal static let secretsSetupKey = ImageAsset(name: "secrets_setup_key")
    internal static let secretsSetupPassphrase = ImageAsset(name: "secrets_setup_passphrase")
    internal static let removeIconPink = ImageAsset(name: "remove_icon_pink")
    internal static let settingsIcon = ImageAsset(name: "settings_icon")
  }
  internal enum SharedImages {
    internal static let cancel = ImageAsset(name: "cancel")
    internal static let e2eVerified = ImageAsset(name: "e2e_verified")
    internal static let forumAvatarIcon = ImageAsset(name: "forum_avatar_icon")
    internal static let privateAvatarIcon = ImageAsset(name: "private_avatar_icon")
  }
}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details

internal struct ImageAsset {
  internal fileprivate(set) var name: String

  #if os(macOS)
  internal typealias Image = NSImage
  #elseif os(iOS) || os(tvOS) || os(watchOS)
  internal typealias Image = UIImage
  #endif

  internal var image: Image {
    let bundle = BundleToken.bundle
    #if os(iOS) || os(tvOS)
    let image = Image(named: name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    let name = NSImage.Name(self.name)
    let image = (bundle == .main) ? NSImage(named: name) : bundle.image(forResource: name)
    #elseif os(watchOS)
    let image = Image(named: name)
    #endif
    guard let result = image else {
      fatalError("Unable to load image named \(name).")
    }
    return result
  }
}

internal extension ImageAsset.Image {
  @available(macOS, deprecated,
    message: "This initializer is unsafe on macOS, please use the ImageAsset.image property")
  convenience init!(asset: ImageAsset) {
    #if os(iOS) || os(tvOS)
    let bundle = BundleToken.bundle
    self.init(named: asset.name, in: bundle, compatibleWith: nil)
    #elseif os(macOS)
    self.init(named: NSImage.Name(asset.name))
    #elseif os(watchOS)
    self.init(named: asset.name)
    #endif
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
