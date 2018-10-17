// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// swiftlint:disable identifier_name line_length type_body_length
internal enum TchapL10n {
  /// Annuler
  internal static let actionCancel = TchapL10n.tr("Tchap", "action_cancel")
  /// Suivant
  internal static let actionNext = TchapL10n.tr("Tchap", "action_next")
  /// L'adresse e-mail ne semble pas valide
  internal static let authenticationErrorInvalidEmail = TchapL10n.tr("Tchap", "authentication_error_invalid_email")
  /// Mot de passe trop court (min %d)
  internal static func authenticationErrorInvalidPassword(_ p1: Int) -> String {
    return TchapL10n.tr("Tchap", "authentication_error_invalid_password", p1)
  }
  /// Mot de passe manquant
  internal static let authenticationErrorMissingPassword = TchapL10n.tr("Tchap", "authentication_error_missing_password")
  /// Cette adresse e-mail n'est pas autorisée
  internal static let authenticationErrorUnauthorizedEmail = TchapL10n.tr("Tchap", "authentication_error_unauthorized_email")
  /// Mot de passe oublié ?
  internal static let authenticationForgotPassword = TchapL10n.tr("Tchap", "authentication_forgot_password")
  /// Adresse email
  internal static let authenticationMailPlaceholder = TchapL10n.tr("Tchap", "authentication_mail_placeholder")
  /// Mot de passe Tchap
  internal static let authenticationPasswordPlaceholder = TchapL10n.tr("Tchap", "authentication_password_placeholder")
  /// Connexion Tchap
  internal static let authenticationTitle = TchapL10n.tr("Tchap", "authentication_title")
  /// Vous n'avez pas autorisé Tchap à accéder à vos contacts locaux
  internal static let contactsAddressBookPermissionDenied = TchapL10n.tr("Tchap", "contacts_address_book_permission_denied")
  /// Permissions requises pour accéder aux contacts locaux
  internal static let contactsAddressBookPermissionRequired = TchapL10n.tr("Tchap", "contacts_address_book_permission_required")
  /// Contacts Tchap
  internal static let contactsMainSection = TchapL10n.tr("Tchap", "contacts_main_section")
  /// Aucun contact
  internal static let contactsNoContact = TchapL10n.tr("Tchap", "contacts_no_contact")
  /// Rechercher
  internal static let contactsSearchBarPlaceholder = TchapL10n.tr("Tchap", "contacts_search_bar_placeholder")
  /// Contacts
  internal static let contactsTabTitle = TchapL10n.tr("Tchap", "contacts_tab_title")
  /// Répertoire Tchap (hors-ligne)
  internal static let contactsUserDirectoryOfflineSection = TchapL10n.tr("Tchap", "contacts_user_directory_offline_section")
  /// Répertoire Tchap
  internal static let contactsUserDirectorySection = TchapL10n.tr("Tchap", "contacts_user_directory_section")
  /// Accéder à un salon public
  internal static let conversationsAccessToPublicRoomsAction = TchapL10n.tr("Tchap", "conversations_access_to_public_rooms_action")
  /// Nouveau salon
  internal static let conversationsCreateRoomAction = TchapL10n.tr("Tchap", "conversations_create_room_action")
  /// Salons publics
  internal static let conversationsDirectorySection = TchapL10n.tr("Tchap", "conversations_directory_section")
  /// Invitations
  internal static let conversationsInvitesSection = TchapL10n.tr("Tchap", "conversations_invites_section")
  /// Conversations
  internal static let conversationsMainSection = TchapL10n.tr("Tchap", "conversations_main_section")
  /// Aucune conversation
  internal static let conversationsNoConversation = TchapL10n.tr("Tchap", "conversations_no_conversation")
  /// Nouvelle discussion
  internal static let conversationsStartChatAction = TchapL10n.tr("Tchap", "conversations_start_chat_action")
  /// Conversations
  internal static let conversationsTabTitle = TchapL10n.tr("Tchap", "conversations_tab_title")
  /// Une erreur est survenue, veuillez réessayer ultérieurement
  internal static let errorMessageDefault = TchapL10n.tr("Tchap", "error_message_default")
  /// Erreur
  internal static let errorTitleDefault = TchapL10n.tr("Tchap", "error_title_default")
  /// Retourner à l'écran de connexion
  internal static let forgotPasswordCheckedEmailDoneAction = TchapL10n.tr("Tchap", "forgot_password_checked_email_done_action")
  /// Votre mot de passe a été réinitialisé. Vous avez été déconnecté de tous les appareils et ne recevez plus de notifications. Pour réactiver les notifications, reconnectez-vous sur chaque appareil.
  internal static let forgotPasswordCheckedEmailInstructions = TchapL10n.tr("Tchap", "forgot_password_checked_email_instructions")
  /// Confirmez votre nouveau mot de passe
  internal static let forgotPasswordFormConfirmPasswordPlaceholder = TchapL10n.tr("Tchap", "forgot_password_form_confirm_password_placeholder")
  /// Adresse email
  internal static let forgotPasswordFormEmailPlaceholder = TchapL10n.tr("Tchap", "forgot_password_form_email_placeholder")
  /// Impossible d'envoyer l'e-mail : adresse non trouvée
  internal static let forgotPasswordFormErrorEmailNotFound = TchapL10n.tr("Tchap", "forgot_password_form_error_email_not_found")
  /// Pour réinitialiser votre mot de passe, saisissez l'adresse email associée à votre compte : 
  internal static let forgotPasswordFormInstructions = TchapL10n.tr("Tchap", "forgot_password_form_instructions")
  /// Nouveau mot de passe
  internal static let forgotPasswordFormPasswordPlaceholder = TchapL10n.tr("Tchap", "forgot_password_form_password_placeholder")
  /// Envoyer l'email de réinitialisation
  internal static let forgotPasswordFormSendEmailAction = TchapL10n.tr("Tchap", "forgot_password_form_send_email_action")
  /// Connexion Tchap
  internal static let forgotPasswordTitle = TchapL10n.tr("Tchap", "forgot_password_title")
  /// J'ai vérifié mon adresse email
  internal static let forgotPasswordVerifyEmailConfirmationAction = TchapL10n.tr("Tchap", "forgot_password_verify_email_confirmation_action")
  /// Impossible de vérifier l'adresse e-mail : assurez-vous d'avoir cliqué sur le lien dans l'e-mail
  internal static let forgotPasswordVerifyEmailErrorEmailNotVerified = TchapL10n.tr("Tchap", "forgot_password_verify_email_error_email_not_verified")
  /// Un email a été envoyé à %@. Une fois que vous aurez suivi le lien qu'il contient, cliquez ci-dessous.
  internal static func forgotPasswordVerifyEmailInstructions(_ p1: String) -> String {
    return TchapL10n.tr("Tchap", "forgot_password_verify_email_instructions", p1)
  }
  /// Chargement en cours…
  internal static let publicRoomsLoadingInProgress = TchapL10n.tr("Tchap", "public_rooms_loading_in_progress")
  /// Rechercher
  internal static let publicRoomsSearchBarPlaceholder = TchapL10n.tr("Tchap", "public_rooms_search_bar_placeholder")
  /// Accéder à un salon
  internal static let publicRoomsTitle = TchapL10n.tr("Tchap", "public_rooms_title")
  /// Confirmer le mot de passe
  internal static let registrationConfirmPasswordPlaceholder = TchapL10n.tr("Tchap", "registration_confirm_password_placeholder")
  /// Je n'ai pas reçu l'email !
  internal static let registrationEmailNotReceivedAction = TchapL10n.tr("Tchap", "registration_email_not_received_action")
  /// Un email vous a été envoyé
  internal static let registrationEmailSentInfo = TchapL10n.tr("Tchap", "registration_email_sent_info")
  /// Veuillez l'ouvrir et cliquer sur le lien proposé pour valider votre inscription
  internal static let registrationEmailSentInstructions = TchapL10n.tr("Tchap", "registration_email_sent_instructions")
  /// Les mots de passe ne correspondent pas
  internal static let registrationErrorPasswordsDontMatch = TchapL10n.tr("Tchap", "registration_error_passwords_dont_match")
  /// Utilisez votre adresse professionnelle
  internal static let registrationMailAdditionalInfo = TchapL10n.tr("Tchap", "registration_mail_additional_info")
  /// Adresse email
  internal static let registrationMailPlaceholder = TchapL10n.tr("Tchap", "registration_mail_placeholder")
  /// Mot de passe Tchap
  internal static let registrationPasswordPlaceholder = TchapL10n.tr("Tchap", "registration_password_placeholder")
  /// Inscription Tchap
  internal static let registrationTitle = TchapL10n.tr("Tchap", "registration_title")
  /// Fichiers
  internal static let roomFilesTabTitle = TchapL10n.tr("Tchap", "room_files_tab_title")
  /// Envoyer un message
  internal static let roomMemberDetailsActionChat = TchapL10n.tr("Tchap", "room_member_details_action_chat")
  /// Membres
  internal static let roomMembersTabTitle = TchapL10n.tr("Tchap", "room_members_tab_title")
  /// Retirer ce salon de la liste des salons publics
  internal static let roomSettingsRemoveFromRoomsDirectory = TchapL10n.tr("Tchap", "room_settings_remove_from_rooms_directory")
  /// Cette action est irréversible.\nVoulez-vous vraiment retirer ce salon des salons publics ?
  internal static let roomSettingsRemoveFromRoomsDirectoryPrompt = TchapL10n.tr("Tchap", "room_settings_remove_from_rooms_directory_prompt")
  /// Paramètres
  internal static let roomSettingsTabTitle = TchapL10n.tr("Tchap", "room_settings_tab_title")
  /// %d membre(s)
  internal static func roomTitleRoomMembersCount(_ p1: Int) -> String {
    return TchapL10n.tr("Tchap", "room_title_room_members_count", p1)
  }
  /// Aucun résultat
  internal static let searchNoResult = TchapL10n.tr("Tchap", "search_no_result")
  /// https://www.tchap.gouv.fr/tac
  internal static let settingsTermConditionsUrl = TchapL10n.tr("Tchap", "settings_term_conditions_url")
  /// J'ai un compte
  internal static let welcomeLoginAction = TchapL10n.tr("Tchap", "welcome_login_action")
  /// Je n'ai pas de compte
  internal static let welcomeRegisterAction = TchapL10n.tr("Tchap", "welcome_register_action")
  /// Bienvenue dans Tchap
  internal static let welcomeTitle = TchapL10n.tr("Tchap", "welcome_title")
}
// swiftlint:enable identifier_name line_length type_body_length

extension TchapL10n {
  private static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: Bundle(for: BundleToken.self), comment: "")
    return String(format: format, locale: Locale.current, arguments: args)
  }
}

private final class BundleToken {}
