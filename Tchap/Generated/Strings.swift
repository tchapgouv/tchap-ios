// swiftlint:disable all
// Generated using SwiftGen, by O.Halligon — https://github.com/SwiftGen/SwiftGen

import Foundation

// swiftlint:disable superfluous_disable_command
// swiftlint:disable file_length

// MARK: - Strings

// swiftlint:disable function_parameter_count identifier_name line_length type_body_length
@objcMembers
public class TchapL10n: NSObject {
  /// Annuler
  public static var actionCancel: String { 
    return TchapL10n.tr("Tchap", "action_cancel") 
  }
  /// Confirmer
  public static var actionConfirm: String { 
    return TchapL10n.tr("Tchap", "action_confirm") 
  }
  /// Inviter
  public static var actionInvite: String { 
    return TchapL10n.tr("Tchap", "action_invite") 
  }
  /// Suivant
  public static var actionNext: String { 
    return TchapL10n.tr("Tchap", "action_next") 
  }
  /// Poursuivre
  public static var actionProceed: String { 
    return TchapL10n.tr("Tchap", "action_proceed") 
  }
  /// Retirer
  public static var actionRemove: String { 
    return TchapL10n.tr("Tchap", "action_remove") 
  }
  /// Valider
  public static var actionValidate: String { 
    return TchapL10n.tr("Tchap", "action_validate") 
  }
  /// Une nouvelle version est disponible. Pour des raisons de sécurité, veuillez mettre à jour votre application avant de poursuivre son utilisation.
  public static var appVersionUpdateCriticalUpdateMessageFallback: String { 
    return TchapL10n.tr("Tchap", "app_version_update_critical_update_message_fallback") 
  }
  /// Ignorer
  public static var appVersionUpdateIgnoreAction: String { 
    return TchapL10n.tr("Tchap", "app_version_update_ignore_action") 
  }
  /// Une nouvelle version est disponible. Nous vous invitons à  mettre à jour votre application.
  public static var appVersionUpdateInfoUpdateMessageFallback: String { 
    return TchapL10n.tr("Tchap", "app_version_update_info_update_message_fallback") 
  }
  /// Plus tard
  public static var appVersionUpdateLaterAction: String { 
    return TchapL10n.tr("Tchap", "app_version_update_later_action") 
  }
  /// Une nouvelle version est disponible, veuillez mettre à jour votre application.
  public static var appVersionUpdateMandatoryUpdateMessageFallback: String { 
    return TchapL10n.tr("Tchap", "app_version_update_mandatory_update_message_fallback") 
  }
  /// Ouvrir l'App Store
  public static var appVersionUpdateOpenAppStoreAction: String { 
    return TchapL10n.tr("Tchap", "app_version_update_open_app_store_action") 
  }
  /// Déconnecter mes appareils et verrouiller mes messages (en cas de piratage de votre compte ou de la perte d'un appareil)
  public static var authenticationChoosePasswordSignoutAllDevices: String { 
    return TchapL10n.tr("Tchap", "authentication_choose_password_signout_all_devices") 
  }
  /// Cette adresse email est déjà utilisée
  public static var authenticationErrorEmailInUse: String { 
    return TchapL10n.tr("Tchap", "authentication_error_email_in_use") 
  }
  /// L'adresse email ne semble pas valide
  public static var authenticationErrorInvalidEmail: String { 
    return TchapL10n.tr("Tchap", "authentication_error_invalid_email") 
  }
  /// Vos trois dernières tentatives de connexion ont échoué. Veuillez réessayer dans 30 minutes
  public static var authenticationErrorLimitExceeded: String { 
    return TchapL10n.tr("Tchap", "authentication_error_limit_exceeded") 
  }
  /// Mot de passe manquant
  public static var authenticationErrorMissingPassword: String { 
    return TchapL10n.tr("Tchap", "authentication_error_missing_password") 
  }
  /// Cette adresse email n'est pas autorisée
  public static var authenticationErrorUnauthorizedEmail: String { 
    return TchapL10n.tr("Tchap", "authentication_error_unauthorized_email") 
  }
  /// Mot de passe oublié ?
  public static var authenticationForgotPassword: String { 
    return TchapL10n.tr("Tchap", "authentication_forgot_password") 
  }
  /// Adresse mail professionnelle
  public static var authenticationMailPlaceholder: String { 
    return TchapL10n.tr("Tchap", "authentication_mail_placeholder") 
  }
  /// Mot de passe Tchap
  public static var authenticationPasswordPlaceholder: String { 
    return TchapL10n.tr("Tchap", "authentication_password_placeholder") 
  }
  /// Se connecter à Tchap
  public static var authenticationPasswordTitle: String { 
    return TchapL10n.tr("Tchap", "authentication_password_title") 
  }
  /// **Continuer avec ProConnect**
  public static var authenticationSsoConnectTitle: String { 
    return TchapL10n.tr("Tchap", "authentication_sso_connect_title") 
  }
  /// Se connecter avec ProConnect
  public static var authenticationSsoTitle: String { 
    return TchapL10n.tr("Tchap", "authentication_sso_title") 
  }
  /// Veuillez saisir votre mot de passe actuel.
  public static var changePasswordCurrentPasswordInstructions: String { 
    return TchapL10n.tr("Tchap", "change_password_current_password_instructions") 
  }
  /// Mot de passe actuel
  public static var changePasswordCurrentPasswordPasswordPlaceholder: String { 
    return TchapL10n.tr("Tchap", "change_password_current_password_password_placeholder") 
  }
  /// Mot de passe actuel
  public static var changePasswordCurrentPasswordTitle: String { 
    return TchapL10n.tr("Tchap", "change_password_current_password_title") 
  }
  /// Valider
  public static var changePasswordCurrentPasswordValidateAction: String { 
    return TchapL10n.tr("Tchap", "change_password_current_password_validate_action") 
  }
  /// Confirmez votre nouveau mot de passe
  public static var changePasswordNewPasswordConfirmPasswordPlaceholder: String { 
    return TchapL10n.tr("Tchap", "change_password_new_password_confirm_password_placeholder") 
  }
  /// Votre nouveau mot de passe doit contenir au moins 8 caractères, avec au moins un caractère de chaque type : majuscule, minuscule, chiffre, caractère spécial.
  public static var changePasswordNewPasswordInstructions: String { 
    return TchapL10n.tr("Tchap", "change_password_new_password_instructions") 
  }
  /// Votre ancien mot de passe est invalide, souhaitez-vous le modifier ?
  public static var changePasswordNewPasswordInvalidOldPassword: String { 
    return TchapL10n.tr("Tchap", "change_password_new_password_invalid_old_password") 
  }
  /// Nouveau mot de passe
  public static var changePasswordNewPasswordPasswordPlaceholder: String { 
    return TchapL10n.tr("Tchap", "change_password_new_password_password_placeholder") 
  }
  /// Votre mot de passe a été changé avec succès.\nVous ne recevrez plus de notifications sur vos autres appareils tant que vous ne vous y reconnecterez pas.
  public static var changePasswordNewPasswordSuccessMessage: String { 
    return TchapL10n.tr("Tchap", "change_password_new_password_success_message") 
  }
  /// Succès
  public static var changePasswordNewPasswordSuccessTitle: String { 
    return TchapL10n.tr("Tchap", "change_password_new_password_success_title") 
  }
  /// Nouveau mot de passe
  public static var changePasswordNewPasswordTitle: String { 
    return TchapL10n.tr("Tchap", "change_password_new_password_title") 
  }
  /// Valider
  public static var changePasswordNewPasswordValidateAction: String { 
    return TchapL10n.tr("Tchap", "change_password_new_password_validate_action") 
  }
  /// Vous n'avez pas autorisé Tchap à accéder à vos contacts locaux
  public static var contactsAddressBookPermissionDenied: String { 
    return TchapL10n.tr("Tchap", "contacts_address_book_permission_denied") 
  }
  /// Permissions requises pour accéder aux contacts locaux
  public static var contactsAddressBookPermissionRequired: String { 
    return TchapL10n.tr("Tchap", "contacts_address_book_permission_required") 
  }
  /// Envoyer une invitation par email
  public static var contactsInviteByEmailButton: String { 
    return TchapL10n.tr("Tchap", "contacts_invite_by_email_button") 
  }
  /// Veuillez saisir l'adresse email de la personne à inviter : 
  public static var contactsInviteByEmailMessage: String { 
    return TchapL10n.tr("Tchap", "contacts_invite_by_email_message") 
  }
  /// Envoyer une invitation
  public static var contactsInviteByEmailTitle: String { 
    return TchapL10n.tr("Tchap", "contacts_invite_by_email_title") 
  }
  /// Inviter en partageant un lien
  public static var contactsInviteByLinkButton: String { 
    return TchapL10n.tr("Tchap", "contacts_invite_by_link_button") 
  }
  /// Inviter des contacts dans Tchap
  public static var contactsInviteToTchapButton: String { 
    return TchapL10n.tr("Tchap", "contacts_invite_to_tchap_button") 
  }
  /// Contacts Tchap
  public static var contactsMainSection: String { 
    return TchapL10n.tr("Tchap", "contacts_main_section") 
  }
  /// Aucun contact
  public static var contactsNoContact: String { 
    return TchapL10n.tr("Tchap", "contacts_no_contact") 
  }
  /// Inviter au salon
  public static var contactsPickerTitle: String { 
    return TchapL10n.tr("Tchap", "contacts_picker_title") 
  }
  /// Les externes ne sont pas autorisés à rejoindre ce salon
  public static var contactsPickerUnauthorizedEmailMessageRestrictedRoom: String { 
    return TchapL10n.tr("Tchap", "contacts_picker_unauthorized_email_message_restricted_room") 
  }
  /// Seuls les membres du domaine %@ sont autorisés
  public static func contactsPickerUnauthorizedEmailMessageUnfederatedRoom(_ p1: String) -> String {
    return TchapL10n.tr("Tchap", "contacts_picker_unauthorized_email_message_unfederated_room", p1)
  }
  /// L'invitation de cet email est refusée
  public static var contactsPickerUnauthorizedEmailTitle: String { 
    return TchapL10n.tr("Tchap", "contacts_picker_unauthorized_email_title") 
  }
  /// Rechercher
  public static var contactsSearchBarPlaceholder: String { 
    return TchapL10n.tr("Tchap", "contacts_search_bar_placeholder") 
  }
  /// Contacts
  public static var contactsTabTitle: String { 
    return TchapL10n.tr("Tchap", "contacts_tab_title") 
  }
  /// Répertoire Tchap (hors-ligne)
  public static var contactsUserDirectoryOfflineSection: String { 
    return TchapL10n.tr("Tchap", "contacts_user_directory_offline_section") 
  }
  /// Répertoire Tchap
  public static var contactsUserDirectorySection: String { 
    return TchapL10n.tr("Tchap", "contacts_user_directory_section") 
  }
  /// Accéder à un salon forum
  public static var conversationsAccessToPublicRoomsAction: String { 
    return TchapL10n.tr("Tchap", "conversations_access_to_public_rooms_action") 
  }
  /// Nouveau salon
  public static var conversationsCreateRoomAction: String { 
    return TchapL10n.tr("Tchap", "conversations_create_room_action") 
  }
  /// Salons forums
  public static var conversationsDirectorySection: String { 
    return TchapL10n.tr("Tchap", "conversations_directory_section") 
  }
  /// Rejeter
  public static var conversationsInviteDecline: String { 
    return TchapL10n.tr("Tchap", "conversations_invite_decline") 
  }
  /// Rejoindre
  public static var conversationsInviteJoin: String { 
    return TchapL10n.tr("Tchap", "conversations_invite_join") 
  }
  /// Invitations
  public static var conversationsInvitesSection: String { 
    return TchapL10n.tr("Tchap", "conversations_invites_section") 
  }
  /// Nouvelle discussion
  public static var conversationsStartChatAction: String { 
    return TchapL10n.tr("Tchap", "conversations_start_chat_action") 
  }
  /// Nouvelle discussion
  public static var createNewDiscussionTitle: String { 
    return TchapL10n.tr("Tchap", "create_new_discussion_title") 
  }
  /// Obtenir de l'aide
  public static var deviceVerificationHelpLabel: String { 
    return TchapL10n.tr("Tchap", "device_verification_help_label") 
  }
  /// Si vous n'avez accès à aucun autre appareil, vous pouvez essayer d'activer la signature croisée dans vos paramètres.
  public static var deviceVerificationSelfVerifyNoOtherVerifiedSessionAvailable: String { 
    return TchapL10n.tr("Tchap", "device_verification_self_verify_no_other_verified_session_available") 
  }
  /// Vérifier l’appareil
  public static var deviceVerificationTitle: String { 
    return TchapL10n.tr("Tchap", "device_verification_title") 
  }
  /// Vous avez bien vérifié cet appareil.\n\nLe partage des clés va s'effectuer progressivement. Les messages se déchiffreront au fur à mesure. Cela peut prendre quelques minutes.
  public static var deviceVerificationVerifiedDescription: String { 
    return TchapL10n.tr("Tchap", "device_verification_verified_description") 
  }
  /// Une erreur est survenue, veuillez réessayer ultérieurement
  public static var errorMessageDefault: String { 
    return TchapL10n.tr("Tchap", "error_message_default") 
  }
  /// Erreur
  public static var errorTitleDefault: String { 
    return TchapL10n.tr("Tchap", "error_title_default") 
  }
  /// Signaler un problème
  public static var eventFormatterReportIncident: String { 
    return TchapL10n.tr("Tchap", "event_formatter_report_incident") 
  }
  /// Un email vous a été envoyé pour renouveler votre compte. Une fois que vous aurez suivi le lien qu’il contient, cliquez ci-dessous.
  public static var expiredAccountAlertMessage: String { 
    return TchapL10n.tr("Tchap", "expired_account_alert_message") 
  }
  /// Votre compte a expiré
  public static var expiredAccountAlertTitle: String { 
    return TchapL10n.tr("Tchap", "expired_account_alert_title") 
  }
  /// Continuer
  public static var expiredAccountOnNewSentEmailButton: String { 
    return TchapL10n.tr("Tchap", "expired_account_on_new_sent_email_button") 
  }
  /// Un nouvel email vous a été envoyé pour renouveler votre compte. Une fois que vous aurez suivi le lien qu’il contient, cliquez ci-dessous.
  public static var expiredAccountOnNewSentEmailMessage: String { 
    return TchapL10n.tr("Tchap", "expired_account_on_new_sent_email_message") 
  }
  /// Email envoyé
  public static var expiredAccountOnNewSentEmailTitle: String { 
    return TchapL10n.tr("Tchap", "expired_account_on_new_sent_email_title") 
  }
  /// Emvoyer un nouvel email
  public static var expiredAccountRequestRenewalEmailButton: String { 
    return TchapL10n.tr("Tchap", "expired_account_request_renewal_email_button") 
  }
  /// Continuer
  public static var expiredAccountResumeButton: String { 
    return TchapL10n.tr("Tchap", "expired_account_resume_button") 
  }
  /// %d messages
  public static func favouriteMessagesMultipleSubtitle(_ p1: Int) -> String {
    return TchapL10n.tr("Tchap", "favourite_messages_multiple_subtitle", p1)
  }
  /// %d message
  public static func favouriteMessagesOneSubtitle(_ p1: Int) -> String {
    return TchapL10n.tr("Tchap", "favourite_messages_one_subtitle", p1)
  }
  /// Messages favoris
  public static var favouriteMessagesTitle: String { 
    return TchapL10n.tr("Tchap", "favourite_messages_title") 
  }
  /// Retourner à l'écran de connexion
  public static var forgotPasswordCheckedEmailDoneAction: String { 
    return TchapL10n.tr("Tchap", "forgot_password_checked_email_done_action") 
  }
  /// Votre mot de passe a été réinitialisé. Vous avez été déconnecté de tous les appareils et ne recevez plus de notifications. Pour réactiver les notifications, reconnectez-vous sur chaque appareil.
  public static var forgotPasswordCheckedEmailInstructions: String { 
    return TchapL10n.tr("Tchap", "forgot_password_checked_email_instructions") 
  }
  /// Confirmez votre nouveau mot de passe
  public static var forgotPasswordFormConfirmPasswordPlaceholder: String { 
    return TchapL10n.tr("Tchap", "forgot_password_form_confirm_password_placeholder") 
  }
  /// Adresse email
  public static var forgotPasswordFormEmailPlaceholder: String { 
    return TchapL10n.tr("Tchap", "forgot_password_form_email_placeholder") 
  }
  /// Impossible d'envoyer l'email : adresse non trouvée
  public static var forgotPasswordFormErrorEmailNotFound: String { 
    return TchapL10n.tr("Tchap", "forgot_password_form_error_email_not_found") 
  }
  /// Pour réinitialiser votre mot de passe, saisissez l'adresse email associée à votre compte : 
  public static var forgotPasswordFormInstructions: String { 
    return TchapL10n.tr("Tchap", "forgot_password_form_instructions") 
  }
  /// Nouveau mot de passe
  public static var forgotPasswordFormPasswordPlaceholder: String { 
    return TchapL10n.tr("Tchap", "forgot_password_form_password_placeholder") 
  }
  /// Envoyer l'email de réinitialisation
  public static var forgotPasswordFormSendEmailAction: String { 
    return TchapL10n.tr("Tchap", "forgot_password_form_send_email_action") 
  }
  /// Connexion Tchap
  public static var forgotPasswordTitle: String { 
    return TchapL10n.tr("Tchap", "forgot_password_title") 
  }
  /// J'ai vérifié mon adresse email
  public static var forgotPasswordVerifyEmailConfirmationAction: String { 
    return TchapL10n.tr("Tchap", "forgot_password_verify_email_confirmation_action") 
  }
  /// Impossible de vérifier l'adresse email : assurez-vous d'avoir cliqué sur le lien dans l'email
  public static var forgotPasswordVerifyEmailErrorEmailNotVerified: String { 
    return TchapL10n.tr("Tchap", "forgot_password_verify_email_error_email_not_verified") 
  }
  /// Si un compte Tchap existe, un email a été envoyé à l'adresse : %@. Une fois que vous aurez suivi le lien qu'il contient, cliquez ci-dessous.
  public static func forgotPasswordVerifyEmailInstructions(_ p1: String) -> String {
    return TchapL10n.tr("Tchap", "forgot_password_verify_email_instructions", p1)
  }
  /// Transférer à
  public static var forwardScreenTitle: String { 
    return TchapL10n.tr("Tchap", "forward_screen_title") 
  }
  /// Pour continuer à utiliser Tchap, vous devez lire et accepter les conditions générales.
  public static var gdprConsentNotGivenAlertMessage: String { 
    return TchapL10n.tr("Tchap", "gdpr_consent_not_given_alert_message") 
  }
  /// Information
  public static var infoTitle: String { 
    return TchapL10n.tr("Tchap", "info_title") 
  }
  /// Vous avez déjà envoyé une invitation à %@.
  public static func inviteAlreadySentByEmail(_ p1: String) -> String {
    return TchapL10n.tr("Tchap", "invite_already_sent_by_email", p1)
  }
  /// Information
  public static var inviteInformationTitle: String { 
    return TchapL10n.tr("Tchap", "invite_information_title") 
  }
  /// Ce contact utilise déjà Tchap, vous pouvez dès à présent lui envoyer un message.
  public static var inviteNotSentForDiscoveredUser: String { 
    return TchapL10n.tr("Tchap", "invite_not_sent_for_discovered_user") 
  }
  /// %@ n’est pas joignable pour l’instant par Tchap.
  public static func inviteNotSentForUnauthorizedEmail(_ p1: String) -> String {
    return TchapL10n.tr("Tchap", "invite_not_sent_for_unauthorized_email", p1)
  }
  /// Echec de l’envoi de l’invitation
  public static var inviteSendingFailedTitle: String { 
    return TchapL10n.tr("Tchap", "invite_sending_failed_title") 
  }
  /// L'invitation a bien été envoyée.\nVous recevrez une notification lorsque\nvotre invité rejoindra la communauté Tchap.
  public static var inviteSendingSucceeded: String { 
    return TchapL10n.tr("Tchap", "invite_sending_succeeded") 
  }
  /// Ce mot de passe a été trouvé dans un dictionnaire, il n’est pas autorisé
  public static var passwordPolicyPwdInDictError: String { 
    return TchapL10n.tr("Tchap", "password_policy_pwd_in_dict_error") 
  }
  /// Mot de passe trop court (min %d)
  public static func passwordPolicyTooShortPwdDetailedError(_ p1: Int) -> String {
    return TchapL10n.tr("Tchap", "password_policy_too_short_pwd_detailed_error", p1)
  }
  /// Mot de passe trop court
  public static var passwordPolicyTooShortPwdError: String { 
    return TchapL10n.tr("Tchap", "password_policy_too_short_pwd_error") 
  }
  /// Ce mot de passe est trop faible. Il doit contenir au moins 8 caractères, avec au moins un caractère de chaque type : majuscule, minuscule, chiffre, caractère spécial
  public static var passwordPolicyWeakPwdError: String { 
    return TchapL10n.tr("Tchap", "password_policy_weak_pwd_error") 
  }
  /// Chargement en cours…
  public static var publicRoomsLoadingInProgress: String { 
    return TchapL10n.tr("Tchap", "public_rooms_loading_in_progress") 
  }
  /// Rechercher
  public static var publicRoomsSearchBarPlaceholder: String { 
    return TchapL10n.tr("Tchap", "public_rooms_search_bar_placeholder") 
  }
  /// Accéder à un forum
  public static var publicRoomsTitle: String { 
    return TchapL10n.tr("Tchap", "public_rooms_title") 
  }
  /// Confirmer le mot de passe
  public static var registrationConfirmPasswordPlaceholder: String { 
    return TchapL10n.tr("Tchap", "registration_confirm_password_placeholder") 
  }
  /// Aller à l'écran de connexion
  public static var registrationEmailLoginAction: String { 
    return TchapL10n.tr("Tchap", "registration_email_login_action") 
  }
  /// Je n'ai pas reçu l'email !
  public static var registrationEmailNotReceivedAction: String { 
    return TchapL10n.tr("Tchap", "registration_email_not_received_action") 
  }
  /// Un email vous a été envoyé à l'adresse suivante, sauf si un compte Tchap lui a déjà été associé : 
  public static var registrationEmailSentInfo: String { 
    return TchapL10n.tr("Tchap", "registration_email_sent_info") 
  }
  /// Merci de cliquer sur le lien proposé dans cet email afin de terminer la création de votre compte. Vous pourrez alors vous connecter en allant sur l'écran de connexion.
  public static var registrationEmailSentInstructions: String { 
    return TchapL10n.tr("Tchap", "registration_email_sent_instructions") 
  }
  /// Le lien a expiré, ou il n'est pas valide
  public static var registrationEmailValidationFailedMsg: String { 
    return TchapL10n.tr("Tchap", "registration_email_validation_failed_msg") 
  }
  /// La validation de l'email a échouée
  public static var registrationEmailValidationFailedTitle: String { 
    return TchapL10n.tr("Tchap", "registration_email_validation_failed_title") 
  }
  /// Les mots de passe ne correspondent pas
  public static var registrationErrorPasswordsDontMatch: String { 
    return TchapL10n.tr("Tchap", "registration_error_passwords_dont_match") 
  }
  /// Vous devez accepter les Conditions Générales d'Utilisation
  public static var registrationErrorUncheckedTerms: String { 
    return TchapL10n.tr("Tchap", "registration_error_unchecked_terms") 
  }
  /// Utilisez votre adresse professionnelle
  public static var registrationMailAdditionalInfo: String { 
    return TchapL10n.tr("Tchap", "registration_mail_additional_info") 
  }
  /// Adresse email
  public static var registrationMailPlaceholder: String { 
    return TchapL10n.tr("Tchap", "registration_mail_placeholder") 
  }
  /// Votre mot de passe doit contenir au moins 8 caractères, avec au moins un caractère de chaque type : majuscule, minuscule, chiffre, caractère spécial
  public static var registrationPasswordAdditionalInfo: String { 
    return TchapL10n.tr("Tchap", "registration_password_additional_info") 
  }
  /// Mot de passe Tchap
  public static var registrationPasswordPlaceholder: String { 
    return TchapL10n.tr("Tchap", "registration_password_placeholder") 
  }
  /// Termes et Conditions
  public static var registrationTermsAndConditionsTitle: String { 
    return TchapL10n.tr("Tchap", "registration_terms_and_conditions_title") 
  }
  /// Accepter les conditions générales d'utilisation
  public static var registrationTermsCheckboxAccessibility: String { 
    return TchapL10n.tr("Tchap", "registration_terms_checkbox_accessibility") 
  }
  /// Lire les conditions générales d'utilisation
  public static var registrationTermsLabelAccessibility: String { 
    return TchapL10n.tr("Tchap", "registration_terms_label_accessibility") 
  }
  /// J'accepte les %@
  public static func registrationTermsLabelFormat(_ p1: String) -> String {
    return TchapL10n.tr("Tchap", "registration_terms_label_format", p1)
  }
  /// Conditions Générales d'Utilisation
  public static var registrationTermsLabelLink: String { 
    return TchapL10n.tr("Tchap", "registration_terms_label_link") 
  }
  /// Inscription Tchap
  public static var registrationTitle: String { 
    return TchapL10n.tr("Tchap", "registration_title") 
  }
  /// Le domaine de votre adresse email n’est pas déclaré dans Tchap. Si vous avez reçu une invitation, vous allez pouvoir créer un compte Tchap « invité », permettant uniquement de participer aux échanges privés auxquels vous êtes convié
  public static var registrationWarningForExternalUser: String { 
    return TchapL10n.tr("Tchap", "registration_warning_for_external_user") 
  }
  /// Information concernant votre inscription
  public static var registrationWarningForExternalUserTitle: String { 
    return TchapL10n.tr("Tchap", "registration_warning_for_external_user_title") 
  }
  /// Analyse antivirus
  public static var roomAttachmentScanStatusInProgressTitle: String { 
    return TchapL10n.tr("Tchap", "room_attachment_scan_status_in_progress_title") 
  }
  /// Le document %@ a été filtré par la politique de sécurité
  public static func roomAttachmentScanStatusInfectedFileInfo(_ p1: String) -> String {
    return TchapL10n.tr("Tchap", "room_attachment_scan_status_infected_file_info", p1)
  }
  /// Fichier bloqué
  public static var roomAttachmentScanStatusInfectedTitle: String { 
    return TchapL10n.tr("Tchap", "room_attachment_scan_status_infected_title") 
  }
  /// Analyse indisponible
  public static var roomAttachmentScanStatusUnavailableTitle: String { 
    return TchapL10n.tr("Tchap", "room_attachment_scan_status_unavailable_title") 
  }
  /// Externes
  public static var roomCategoryExternRoom: String { 
    return TchapL10n.tr("Tchap", "room_category_extern_room") 
  }
  /// Forum
  public static var roomCategoryForumRoom: String { 
    return TchapL10n.tr("Tchap", "room_category_forum_room") 
  }
  /// Info
  public static var roomCategoryInfoRoom: String { 
    return TchapL10n.tr("Tchap", "room_category_info_room") 
  }
  /// Privé
  public static var roomCategoryPrivateRoom: String { 
    return TchapL10n.tr("Tchap", "room_category_private_room") 
  }
  /// Ajouter une photo
  public static var roomCreationAddAvatarAction: String { 
    return TchapL10n.tr("Tchap", "room_creation_add_avatar_action") 
  }
  /// Accessible à tous les utilisateurs et aux invités externes sur invitation d’un administrateur.
  public static var roomCreationExternRoomInfo: String { 
    return TchapL10n.tr("Tchap", "room_creation_extern_room_info") 
  }
  /// Accessible à tous les utilisateurs à partir de la liste des forums ou d’un lien partagé.
  public static var roomCreationForumRoomInfo: String { 
    return TchapL10n.tr("Tchap", "room_creation_forum_room_info") 
  }
  /// Nommer le salon
  public static var roomCreationNamePlaceholder: String { 
    return TchapL10n.tr("Tchap", "room_creation_name_placeholder") 
  }
  /// Accessible à tous les utilisateurs sur invitation d’un administrateur.
  public static var roomCreationPrivateRoomInfo: String { 
    return TchapL10n.tr("Tchap", "room_creation_private_room_info") 
  }
  /// Limiter l'accès à ce salon aux membres du domaine "%@"
  public static func roomCreationPublicRoomFederationTitle(_ p1: String) -> String {
    return TchapL10n.tr("Tchap", "room_creation_public_room_federation_title", p1)
  }
  /// Un forum peut être rejoint par tous les utilisateurs excepté les invités externes. Il ne doit contenir aucune donnée sensible.
  public static var roomCreationPublicVisibilityInfo: String { 
    return TchapL10n.tr("Tchap", "room_creation_public_visibility_info") 
  }
  /// Type de salon
  public static var roomCreationRoomTypeTitle: String { 
    return TchapL10n.tr("Tchap", "room_creation_room_type_title") 
  }
  /// Nouveau salon
  public static var roomCreationTitle: String { 
    return TchapL10n.tr("Tchap", "room_creation_title") 
  }
  /// En savoir plus.
  public static var roomDecryptionErrorFaqLinkMessage: String { 
    return TchapL10n.tr("Tchap", "room_decryption_error_faq_link_message") 
  }
  /// Mettre en favoris
  public static var roomEventActionAddFavourite: String { 
    return TchapL10n.tr("Tchap", "room_event_action_add_favourite") 
  }
  /// Favoris
  public static var roomEventActionFavourite: String { 
    return TchapL10n.tr("Tchap", "room_event_action_favourite") 
  }
  /// Transférer
  public static var roomEventActionForward: String { 
    return TchapL10n.tr("Tchap", "room_event_action_forward") 
  }
  /// Retirer des favoris
  public static var roomEventActionRemoveFavourite: String { 
    return TchapL10n.tr("Tchap", "room_event_action_remove_favourite") 
  }
  /// Fichiers
  public static var roomFilesTabTitle: String { 
    return TchapL10n.tr("Tchap", "room_files_tab_title") 
  }
  /// Cet utilisateur est déjà membre du salon ou n'est pas autorisé à le rejoindre.
  public static var roomInviteErrorActionForbidden: String { 
    return TchapL10n.tr("Tchap", "room_invite_error_action_forbidden") 
  }
  /// Veuillez saisir le nom d'un correspondant pour le rechercher dans l'annuaire
  public static var roomInviteSearchConsign: String { 
    return TchapL10n.tr("Tchap", "room_invite_search_consign") 
  }
  /// Envoyer un message
  public static var roomMemberDetailsActionChat: String { 
    return TchapL10n.tr("Tchap", "room_member_details_action_chat") 
  }
  /// Fichiers partagés
  public static var roomMemberDetailsFiles: String { 
    return TchapL10n.tr("Tchap", "room_member_details_files") 
  }
  /// Voulez-vous vraiment retirer %@ de ce salon ?
  public static func roomMembersRemovePromptMsg(_ p1: String) -> String {
    return TchapL10n.tr("Tchap", "room_members_remove_prompt_msg", p1)
  }
  /// Membres
  public static var roomMembersTabTitle: String { 
    return TchapL10n.tr("Tchap", "room_members_tab_title") 
  }
  /// Le fichier est trop lourd pour être envoyé. La taille limite est de %ldMo, mais la taille de votre fichier est de %ldMo.
  public static func roomSendFileTooBigMessage(_ p1: Int, _ p2: Int) -> String {
    return TchapL10n.tr("Tchap", "room_send_file_too_big_message", p1, p2)
  }
  /// Erreur d'envoi
  public static var roomSendFileTooBigTitle: String { 
    return TchapL10n.tr("Tchap", "room_send_file_too_big_title") 
  }
  /// Ce changement n’est pas supporté actuellement car le salon est accessible par lien. Il sera supporté prochainement
  public static var roomSettingsAllowExternalUsersForbidden: String { 
    return TchapL10n.tr("Tchap", "room_settings_allow_external_users_forbidden") 
  }
  /// Autoriser l’accès aux externes à ce salon
  public static var roomSettingsAllowExternalUsersToJoin: String { 
    return TchapL10n.tr("Tchap", "room_settings_allow_external_users_to_join") 
  }
  /// Cette action est irréversible.\nVoulez-vous vraiment autoriser les externes à rejoindre ce salon ?
  public static var roomSettingsAllowExternalUsersToJoinPromptMsg: String { 
    return TchapL10n.tr("Tchap", "room_settings_allow_external_users_to_join_prompt_msg") 
  }
  /// Activer l’accès au salon par lien
  public static var roomSettingsEnableRoomAccessByLink: String { 
    return TchapL10n.tr("Tchap", "room_settings_enable_room_access_by_link") 
  }
  /// Les utilisateurs pourront rejoindre ce salon à partir d'un lien puis le partager à d'autres utilisateurs.
  public static var roomSettingsEnableRoomAccessByLinkInfoOff: String { 
    return TchapL10n.tr("Tchap", "room_settings_enable_room_access_by_link_info_off") 
  }
  /// Les autres utilisateurs peuvent rejoindre ce salon à partir du lien suivant :
  public static var roomSettingsEnableRoomAccessByLinkInfoOn: String { 
    return TchapL10n.tr("Tchap", "room_settings_enable_room_access_by_link_info_on") 
  }
  /// Les autres utilisateurs peuvent rejoindre ce salon à partir du lien suivant (une invitation reste nécessaire pour les externes) :
  public static var roomSettingsEnableRoomAccessByLinkInfoOnWithLimitation: String { 
    return TchapL10n.tr("Tchap", "room_settings_enable_room_access_by_link_info_on_with_limitation") 
  }
  /// Quitter ce salon
  public static var roomSettingsLeaveRoom: String { 
    return TchapL10n.tr("Tchap", "room_settings_leave_room") 
  }
  /// Retirer ce salon de la liste des forums
  public static var roomSettingsRemoveFromRoomsDirectory: String { 
    return TchapL10n.tr("Tchap", "room_settings_remove_from_rooms_directory") 
  }
  /// Cette action est irréversible.\nVoulez-vous vraiment retirer ce salon de la liste des forums ?
  public static var roomSettingsRemoveFromRoomsDirectoryPrompt: String { 
    return TchapL10n.tr("Tchap", "room_settings_remove_from_rooms_directory_prompt") 
  }
  /// Ce salon n’est pas accessible par lien
  public static var roomSettingsRoomAccessByLinkDisabled: String { 
    return TchapL10n.tr("Tchap", "room_settings_room_access_by_link_disabled") 
  }
  /// Ce salon est accessible par lien
  public static var roomSettingsRoomAccessByLinkEnabled: String { 
    return TchapL10n.tr("Tchap", "room_settings_room_access_by_link_enabled") 
  }
  /// Ce changement n’est pas supporté actuellement car les externes sont autorisés à rejoindre ce salon. Il sera supporté prochainement
  public static var roomSettingsRoomAccessByLinkForbidden: String { 
    return TchapL10n.tr("Tchap", "room_settings_room_access_by_link_forbidden") 
  }
  /// lien invalide
  public static var roomSettingsRoomAccessByLinkInvalid: String { 
    return TchapL10n.tr("Tchap", "room_settings_room_access_by_link_invalid") 
  }
  /// Partager le lien
  public static var roomSettingsRoomAccessByLinkShare: String { 
    return TchapL10n.tr("Tchap", "room_settings_room_access_by_link_share") 
  }
  /// Accès par lien
  public static var roomSettingsRoomAccessByLinkTitle: String { 
    return TchapL10n.tr("Tchap", "room_settings_room_access_by_link_title") 
  }
  /// Les externes ne sont pas autorisés à rejoindre ce salon
  public static var roomSettingsRoomAccessRestricted: String { 
    return TchapL10n.tr("Tchap", "room_settings_room_access_restricted") 
  }
  /// Gestion des comptes externes
  public static var roomSettingsRoomAccessTitle: String { 
    return TchapL10n.tr("Tchap", "room_settings_room_access_title") 
  }
  /// Les externes sont autorisés à rejoindre ce salon
  public static var roomSettingsRoomAccessUnrestricted: String { 
    return TchapL10n.tr("Tchap", "room_settings_room_access_unrestricted") 
  }
  /// Paramètres
  public static var roomSettingsTabTitle: String { 
    return TchapL10n.tr("Tchap", "room_settings_tab_title") 
  }
  /// Privé avec externes
  public static var roomTitleExternRoom: String { 
    return TchapL10n.tr("Tchap", "room_title_extern_room") 
  }
  /// Forum
  public static var roomTitleForumRoom: String { 
    return TchapL10n.tr("Tchap", "room_title_forum_room") 
  }
  /// Privé
  public static var roomTitlePrivateRoom: String { 
    return TchapL10n.tr("Tchap", "room_title_private_room") 
  }
  /// %d
  public static func roomTitleRoomMembersCount(_ p1: Int) -> String {
    return TchapL10n.tr("Tchap", "room_title_room_members_count", p1)
  }
  /// Salon accessible aux externes
  public static var roomTitleUnrestrictedRoom: String { 
    return TchapL10n.tr("Tchap", "room_title_unrestricted_room") 
  }
  /// Aucun résultat
  public static var searchNoResult: String { 
    return TchapL10n.tr("Tchap", "search_no_result") 
  }
  /// Clé copiée
  public static var secretsSetupRecoveryKeyExportActionDone: String { 
    return TchapL10n.tr("Tchap", "secrets_setup_recovery_key_export_action_done") 
  }
  /// Activer
  public static var secretsSetupRecoveryKeyInviteButtonOk: String { 
    return TchapL10n.tr("Tchap", "secrets_setup_recovery_key_invite_button_ok") 
  }
  /// Activez cette fonction pour ne jamais perdre l’accès à vos messages suite à une déconnexion.
  public static var secretsSetupRecoveryKeyInviteMessage: String { 
    return TchapL10n.tr("Tchap", "secrets_setup_recovery_key_invite_message") 
  }
  /// Sauvegarde automatique des messages
  public static var secretsSetupRecoveryKeyInviteTitle: String { 
    return TchapL10n.tr("Tchap", "secrets_setup_recovery_key_invite_title") 
  }
  /// Attention : c'est la seule fois que votre code est affiché !
  public static var secretsSetupRecoveryKeyWarning: String { 
    return TchapL10n.tr("Tchap", "secrets_setup_recovery_key_warning") 
  }
  /// Réinitialiser
  public static var securityCrossSigningResetActionTitle: String { 
    return TchapL10n.tr("Tchap", "security_cross_signing_reset_action_title") 
  }
  /// Faites cette opération seulement si vous avez perdu tous vos autres appareils vérifiés.
  public static var securityCrossSigningResetMessage: String { 
    return TchapL10n.tr("Tchap", "security_cross_signing_reset_message") 
  }
  /// Êtes-vous sûr ?
  public static var securityCrossSigningResetTitle: String { 
    return TchapL10n.tr("Tchap", "security_cross_signing_reset_title") 
  }
  /// Activer la signature croisée
  public static var securityCrossSigningSetupTitle: String { 
    return TchapL10n.tr("Tchap", "security_cross_signing_setup_title") 
  }
  /// Changer le mot de passe réinitialise les clés de chiffrement sur tous les appareils, rendant l’historique des discussions illisible: pensez d'abord à exporter vos clés pour pouvoir les ré-importer après le changement de mot de passe.
  public static var settingsChangePwdCaution: String { 
    return TchapL10n.tr("Tchap", "settings_change_pwd_caution") 
  }
  /// Je vais patienter
  public static var settingsChangePwdKeyBackupInProgressAlertCancelAction: String { 
    return TchapL10n.tr("Tchap", "settings_change_pwd_key_backup_in_progress_alert_cancel_action") 
  }
  /// Je ne veux plus de mes messages chiffrés
  public static var settingsChangePwdKeyBackupInProgressAlertDiscardKeyBackupAction: String { 
    return TchapL10n.tr("Tchap", "settings_change_pwd_key_backup_in_progress_alert_discard_key_backup_action") 
  }
  /// Sauvegarde de clés en cours. Si vous changez votre mot de passe maintenant vous n'aurez plus accès à vos messages chiffrés.
  public static var settingsChangePwdKeyBackupInProgressAlertTitle: String { 
    return TchapL10n.tr("Tchap", "settings_change_pwd_key_backup_in_progress_alert_title") 
  }
  /// Changer le mot de passe sans sauvegarde de clés
  public static var settingsChangePwdNonExistingKeyBackupAlertDiscardKeyBackupAction: String { 
    return TchapL10n.tr("Tchap", "settings_change_pwd_non_existing_key_backup_alert_discard_key_backup_action") 
  }
  /// Mettre en place la sauvegarde de clés
  public static var settingsChangePwdNonExistingKeyBackupAlertSetupKeyBackupAction: String { 
    return TchapL10n.tr("Tchap", "settings_change_pwd_non_existing_key_backup_alert_setup_key_backup_action") 
  }
  /// Changer le mot de passe réinitialise les clés de chiffrement sur tous les appareils, rendant l’historique des discussions illisible: pensez à mettre en place la sauvegarde de vos clés avant ce changement.
  public static var settingsChangePwdNonExistingKeyBackupAlertTitle: String { 
    return TchapL10n.tr("Tchap", "settings_change_pwd_non_existing_key_backup_alert_title") 
  }
  /// Utiliser les adresses emails pour retrouver des utilisateurs
  public static var settingsContactsDiscoverMatrixUsers: String { 
    return TchapL10n.tr("Tchap", "settings_contacts_discover_matrix_users") 
  }
  /// Importer les clés
  public static var settingsCryptoImport: String { 
    return TchapL10n.tr("Tchap", "settings_crypto_import") 
  }
  /// Fichier de clés invalide.
  public static var settingsCryptoImportInvalidFile: String { 
    return TchapL10n.tr("Tchap", "settings_crypto_import_invalid_file") 
  }
  /// En savoir plus.
  public static var settingsEnableEmailNotifLink: String { 
    return TchapL10n.tr("Tchap", "settings_enable_email_notif_link") 
  }
  /// Recevez un e-mail si au moins un message récent non lu pendant 72h.
  public static var settingsEnableEmailNotifText: String { 
    return TchapL10n.tr("Tchap", "settings_enable_email_notif_text") 
  }
  /// Le compte correspond à tous vos appareils connectés à Tchap.
  public static var settingsEnableInappNotificationsDescription: String { 
    return TchapL10n.tr("Tchap", "settings_enable_inapp_notifications_description") 
  }
  /// Sans cette autorisation, les messages et appels entrants ne seront pas notifiés.
  public static var settingsEnablePushNotifText: String { 
    return TchapL10n.tr("Tchap", "settings_enable_push_notif_text") 
  }
  /// Les autres utilisateurs ne pourront pas découvrir mon compte lors de leurs recherches
  public static var settingsHideFromUsersDirectorySummary: String { 
    return TchapL10n.tr("Tchap", "settings_hide_from_users_directory_summary") 
  }
  /// Inscrire mon compte sur liste rouge
  public static var settingsHideFromUsersDirectoryTitle: String { 
    return TchapL10n.tr("Tchap", "settings_hide_from_users_directory_title") 
  }
  /// Notification par e-mail
  public static var settingsNotificationEmail: String { 
    return TchapL10n.tr("Tchap", "settings_notification_email") 
  }
  /// Préférences
  public static var settingsPreferences: String { 
    return TchapL10n.tr("Tchap", "settings_preferences") 
  }
  /// Pour désactiver cette option, vous devez accepter que votre adresse email soit visible des autres utilisateurs lors de leurs recherches.
  public static var settingsShowExternalUserInUsersDirectoryPrompt: String { 
    return TchapL10n.tr("Tchap", "settings_show_external_user_in_users_directory_prompt") 
  }
  /// Les invitations, expulsions et bannissements ne sont pas concernés
  public static var settingsShowJoinLeaveMessagesSummary: String { 
    return TchapL10n.tr("Tchap", "settings_show_join_leave_messages_summary") 
  }
  /// Afficher les notifications d’arrivée et de départ
  public static var settingsShowJoinLeaveMessagesTitle: String { 
    return TchapL10n.tr("Tchap", "settings_show_join_leave_messages_title") 
  }
  /// Afficher les changements d’avatar
  public static var settingsShowProfileChangesMessagesTitle: String { 
    return TchapL10n.tr("Tchap", "settings_show_profile_changes_messages_title") 
  }
  /// Échec d'envoi. Veuillez renouveler cet envoi depuis l'application
  public static var shareExtensionFailedToShareInEmptyDiscussion: String { 
    return TchapL10n.tr("Tchap", "share_extension_failed_to_share_in_empty_discussion") 
  }
  /// Inviter à rejoindre Tchap
  public static var sideMenuActionInviteFriends: String { 
    return TchapL10n.tr("Tchap", "side_menu_action_invite_friends") 
  }
  /// Termes et conditions
  public static var sideMenuActionTermsAndConditions: String { 
    return TchapL10n.tr("Tchap", "side_menu_action_terms_and_conditions") 
  }
  /// Votre correspondant a quitté définitivement cette discussion.\nVous devez en créer une nouvelle pour le recontacter, s'il est toujours joignable sur Tchap.
  public static var tchapCannotInviteDeactivatedAccountUser: String { 
    return TchapL10n.tr("Tchap", "tchap_cannot_invite_deactivated_account_user") 
  }
  /// Vous n'avez pas de message direct avec %@, voulez-vous lui envoyer une invitation ?
  public static func tchapDialogPromptNewDirectChat(_ p1: String) -> String {
    return TchapL10n.tr("Tchap", "tchap_dialog_prompt_new_direct_chat", p1)
  }
  /// Vous n'êtes pas autorisé à rejoindre cette conversation. Une invitation est nécessaire.
  public static var tchapRoomAccessUnauthorized: String { 
    return TchapL10n.tr("Tchap", "tchap_room_access_unauthorized") 
  }
  /// Voulez-vous vraiment quitter cette conversation ?\n\nElle ne sera plus administrée, et vous risquez de ne plus pouvoir la joindre de nouveau.
  public static var tchapRoomAdminLeavePromptMsg: String { 
    return TchapL10n.tr("Tchap", "tchap_room_admin_leave_prompt_msg") 
  }
  /// Ce lien n'est pas valide
  public static var tchapRoomInvalidLink: String { 
    return TchapL10n.tr("Tchap", "tchap_room_invalid_link") 
  }
  /// Vous avez rencontré un souci durant votre appel VoIP. Dites-nous ce qui s'est passé :
  public static var voidReportIncidentDescription: String { 
    return TchapL10n.tr("Tchap", "void_report_incident_description") 
  }
  /// Signaler un problème VoIP
  public static var voidReportIncidentTitle: String { 
    return TchapL10n.tr("Tchap", "void_report_incident_title") 
  }
  /// Attention
  public static var warningTitle: String { 
    return TchapL10n.tr("Tchap", "warning_title") 
  }
  /// J'ai un compte
  public static var welcomeLoginAction: String { 
    return TchapL10n.tr("Tchap", "welcome_login_action") 
  }
  /// Se connecter par mot de passe
  public static var welcomePasswordTitle: String { 
    return TchapL10n.tr("Tchap", "welcome_password_title") 
  }
  /// → Qu'est-ce que ProConnect ?
  public static var welcomeProConnectInfo: String { 
    return TchapL10n.tr("Tchap", "welcome_pro_connect_info") 
  }
  /// Se connecter avec\n**ProConnect**
  public static var welcomeProConnectTitle: String { 
    return TchapL10n.tr("Tchap", "welcome_pro_connect_title") 
  }
  /// Je n'ai pas de compte
  public static var welcomeRegisterAction: String { 
    return TchapL10n.tr("Tchap", "welcome_register_action") 
  }
  /// La messagerie instantanée du secteur public
  public static var welcomeSubtitle: String { 
    return TchapL10n.tr("Tchap", "welcome_subtitle") 
  }
  /// Bienvenue dans Tchap
  public static var welcomeTitle: String { 
    return TchapL10n.tr("Tchap", "welcome_title") 
  }
  /// Vous ne pouvez pas rejeter cette invitation
  public static var youCannotRejectThisInvite: String { 
    return TchapL10n.tr("Tchap", "You cannot reject this invite") 
  }
}
// swiftlint:enable function_parameter_count identifier_name line_length type_body_length

// MARK: - Implementation Details

extension TchapL10n {
  static func tr(_ table: String, _ key: String, _ args: CVarArg...) -> String {
    let format = NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    let locale = LocaleProvider.locale ?? Locale.current    
    return String(format: format, locale: locale, arguments: args)
  }
  /// The bundle to load strings from. This will be the app's bundle unless running
  /// the UI tests target, in which case the strings are contained in the tests bundle.
  static let bundle: Bundle = {
    if ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil {
      // The tests bundle is embedded inside a runner. Find the bundle for VectorL10n.
      return Bundle(for: VectorL10n.self)
    }
    return Bundle.app
  }()
}

