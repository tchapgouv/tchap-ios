## Changes in 2.2.0 (2022-11-08)

🙌 Improvements

- Replace the Authentication and Registration modules by the Element ones ([#657](https://github.com/tchapgouv/tchap-ios/issues/657))
- [Account creation] Add Terms & conditions to the workflow ([#675](https://github.com/tchapgouv/tchap-ios/issues/675))
- [Forgot password] Configure default value for devices disconnection ([#676](https://github.com/tchapgouv/tchap-ios/issues/676))

🐛 Bugfixes

- [Access to a forum] Update forum icon in forums directory ([#668](https://github.com/tchapgouv/tchap-ios/issues/668))

🧱 Build

- Remove target.yml files from each target and merge them ([#656](https://github.com/tchapgouv/tchap-ios/issues/656))


## Changes in 2.1.0 (2022-08-29)

🙌 Improvements

- [Settings] Move back to Element settings screen ([#576](https://github.com/tchapgouv/tchap-ios/issues/576))
- [Settings] Adjust Security section ([#577](https://github.com/tchapgouv/tchap-ios/issues/577))
- [Cross signing] Disable the cross-signing logic until we are ready to support it ([#605](https://github.com/tchapgouv/tchap-ios/issues/605))
- Replace Contacts picker by the Element iOS one ([#638](https://github.com/tchapgouv/tchap-ios/issues/638))

🐛 Bugfixes

- Fix Auto-capitalization and Keyboard type for Room creation Title Field ([#621](https://github.com/tchapgouv/tchap-ios/issues/621))
- Rename exported keys file to tchap-keys ([#647](https://github.com/tchapgouv/tchap-ios/issues/647))
- [Room timeline] Add the room settings shortcuts in the room timeline ([#658](https://github.com/tchapgouv/tchap-ios/issues/658))

🧱 Build

- [Project Cleaning] Remove the compilation flags for the enabled features ([#643](https://github.com/tchapgouv/tchap-ios/issues/643))
- Renew Tchap/Btchap/TchapDev provisioning profiles ([#644](https://github.com/tchapgouv/tchap-ios/issues/644))
- Fix build for Btchap/DevTchap targets after rebase ([#650](https://github.com/tchapgouv/tchap-ios/issues/650))
- Disable currently unwanted Fastlane task for Codecov ([#654](https://github.com/tchapgouv/tchap-ios/issues/654))

Others

- [Project cleaning] Remove unused Tchap source files ([#636](https://github.com/tchapgouv/tchap-ios/issues/636))
- Remove CorruptData and IgnoredUsers observers from AppCoordinator #641 ([#641](https://github.com/tchapgouv/tchap-ios/issues/641))


## Changes in 2.0.5 (2022-07-25)

🐛 Bugfixes

- [Room List] Create discussion button is missing in the people tab ([#607](https://github.com/tchapgouv/tchap-ios/issues/607))
- [Reset pwd] unexpected "Optional" word in the message displayed ([#609](https://github.com/tchapgouv/tchap-ios/issues/609))
- Fix dark mode for welcome, login, registration and forgot password screens ([#628](https://github.com/tchapgouv/tchap-ios/issues/628))


## Changes in 2.0.4 (2022-07-20)

🙌 Improvements

- Replace faq URL ([#617](https://github.com/tchapgouv/tchap-ios/issues/617))
- Reword account deactivation button on the Settings screen. ([#624](https://github.com/tchapgouv/tchap-ios/issues/624))

🐛 Bugfixes

- [Room settings] Notification page still has green UI elements ([#601](https://github.com/tchapgouv/tchap-ios/issues/601))
- Activate access by link on private room is temporary null ([#602](https://github.com/tchapgouv/tchap-ios/issues/602))
- [Rooms List] Wrong tint color for Notification icons ([#618](https://github.com/tchapgouv/tchap-ios/issues/618))


## Changes in 2.0.3 (2022-07-13)

🐛 Bugfixes

- On reply messages, redirection to user card doesn't work when tapping on user's name ([#596](https://github.com/tchapgouv/tchap-ios/issues/596))
- Fix SplitView issue when joining a forum on iPad ([#598](https://github.com/tchapgouv/tchap-ios/issues/598))
- Application is frozen after renewing the account ([#615](https://github.com/tchapgouv/tchap-ios/issues/615))


## Changes in 2.0.2 (2022-06-30)

✨ Features

- Rooms in spaces aren't visible ([#549](https://github.com/tchapgouv/tchap-ios/issues/549))

🙌 Improvements

- [Rooms list] Make shrinkable the sections ([#495](https://github.com/tchapgouv/tchap-ios/issues/495))
- [Nouveau salon] Fix icons for salon type ([#565](https://github.com/tchapgouv/tchap-ios/issues/565))

🧱 Build

- Add missing LSSupportsOpeningDocumentsInPlace key to info plist ([#590](https://github.com/tchapgouv/tchap-ios/issues/590))


## Changes in 2.0.1 (2022-06-22)

✨ Features

- Add clear cache option from the Apple settings ([#579](https://github.com/tchapgouv/tchap-ios/issues/579))

🙌 Improvements

- [Rooms list] Switch back to the Element room cell views ([#468](https://github.com/tchapgouv/tchap-ios/issues/468))
- [Salons] Replace tab icon ([#562](https://github.com/tchapgouv/tchap-ios/issues/562))
- [Salons] Replace section name "Conversations" with "Salons" ([#563](https://github.com/tchapgouv/tchap-ios/issues/563))
- Turn on by default the message bubbles ([#575](https://github.com/tchapgouv/tchap-ios/issues/575))

🐛 Bugfixes

- Crash on new login with an expired account ([#477](https://github.com/tchapgouv/tchap-ios/issues/477))
- [External Users] Hide the unauthorized actions ([#564](https://github.com/tchapgouv/tchap-ios/issues/564))
- UI issue with mention Pills on iOS 15 ([#582](https://github.com/tchapgouv/tchap-ios/issues/582))
- Crash when sending a Rageshake ([#586](https://github.com/tchapgouv/tchap-ios/issues/586))


## Changes in 2.0.0 (2022-06-07)

🐛 Bugfixes

- Some icons have the wrong tint color ([#481](https://github.com/tchapgouv/tchap-ios/issues/481))
- Button icon show one notification ([#552](https://github.com/tchapgouv/tchap-ios/issues/552))
- [Account creation] Redirection to Tchap/Btchap failed ([#553](https://github.com/tchapgouv/tchap-ios/issues/553))
- Tchap is not opened on permalink ([#557](https://github.com/tchapgouv/tchap-ios/issues/557))


## Changes in 1.99.3 (2022-05-30)

🙌 Improvements

- Enable message edition and reaction by default in Tchap ([#532](https://github.com/tchapgouv/tchap-ios/issues/532))
- [DM] Unable to start a new DM with a contact who left the previous DM ([#535](https://github.com/tchapgouv/tchap-ios/issues/535))
- Improve the room member details ([#543](https://github.com/tchapgouv/tchap-ios/issues/543))

🐛 Bugfixes

- Room avatars are missing ([#526](https://github.com/tchapgouv/tchap-ios/issues/526))
- Crash when the user joins a forum ([#531](https://github.com/tchapgouv/tchap-ios/issues/531))
- Hide the Thread option in the selected message options ([#540](https://github.com/tchapgouv/tchap-ios/issues/540))


## Changes in 1.99.2 (2022-05-17)

🐛 Bugfixes

- Messages are missing in the room timelines ([#527](https://github.com/tchapgouv/tchap-ios/issues/527))
- Unexpected logout ([#528](https://github.com/tchapgouv/tchap-ios/issues/528))


## Changes in v1.99.1 (2022-05-10)

🙌 Improvements

- Remove the potential confirmation popup before starting a new discussion ([#447](https://github.com/tchapgouv/tchap-ios/issues/447))
- [Left panel] add an option "Inviter à rejoindre Tchap" ([#449](https://github.com/tchapgouv/tchap-ios/issues/449))
- Change sygnal server url ([#454](https://github.com/tchapgouv/tchap-ios/issues/454))
- [Room Settings] Move back to the Element screen ([#456](https://github.com/tchapgouv/tchap-ios/issues/456))
- Adjust the room settings in case of a DM ([#462](https://github.com/tchapgouv/tchap-ios/issues/462))
- Hide Integration option from the global room settings ([#463](https://github.com/tchapgouv/tchap-ios/issues/463))
- [Room Settings] Restore the room access by link ([#464](https://github.com/tchapgouv/tchap-ios/issues/464))
- [Room Settings] Restore the potential room access by the external accounts ([#465](https://github.com/tchapgouv/tchap-ios/issues/465))
- Make optional the edition and the reaction on message ([#470](https://github.com/tchapgouv/tchap-ios/issues/470))
- [Rooms list] restore the Element tabs : Fav/Direct/Rooms ([#500](https://github.com/tchapgouv/tchap-ios/issues/500))
- Remove the hexagonal shape on Room avatar ([#513](https://github.com/tchapgouv/tchap-ios/issues/513))


## Changes in 1.99.0 (2022-04-12)

🙌 Improvements

- Ré-alignement du système de thème avec Element ([#395](https://github.com/tchapgouv/tchap-ios/issues/395))
- Suppression de TCNavigationController (remplacé par RiotNavigationController) ([#406](https://github.com/tchapgouv/tchap-ios/issues/406))
- Nettoyage des fichiers de configuration du projet ([#410](https://github.com/tchapgouv/tchap-ios/issues/410))
- Ré-alignement de la cible de notification avec Element ([#411](https://github.com/tchapgouv/tchap-ios/issues/411))
- Ré-alignement de l’extension de partage avec Element ([#412](https://github.com/tchapgouv/tchap-ios/issues/412))
- Nettoyage des assets (doublons et ré-alignement sur Element) ([#422](https://github.com/tchapgouv/tchap-ios/issues/422))
- Support and test the new RoomNotificationSettings ([#429](https://github.com/tchapgouv/tchap-ios/issues/429))
- Corrections sur l’intégration de l’extension de partage ([#432](https://github.com/tchapgouv/tchap-ios/issues/432))
- Mise à jour du transfert de messages avec les évolutions d’Element ([#433](https://github.com/tchapgouv/tchap-ios/issues/433))
- Refresh the RoomViewController with the Element one ([#440](https://github.com/tchapgouv/tchap-ios/issues/440))
- Add the left panel in Tchap-iOS ([#441](https://github.com/tchapgouv/tchap-ios/issues/441))
- Update the Tchap architecture with the Element one ([#448](https://github.com/tchapgouv/tchap-ios/issues/448))
- Plug the rooms list to the new rooms fetchers ([#460](https://github.com/tchapgouv/tchap-ios/issues/460))
- Enable dark mode ([#485](https://github.com/tchapgouv/tchap-ios/issues/485))
- Update pinned certificates

🐛 Bugfixes

- Update the bg color of the invite buttons and missedNotif badge ([#425](https://github.com/tchapgouv/tchap-ios/issues/425))
- Fix rooms statuses in Rooms list ([#445](https://github.com/tchapgouv/tchap-ios/issues/445))
- Fix Invite by email a new user failed ([#479](https://github.com/tchapgouv/tchap-ios/issues/479))
- Hide the session verification based on the secure storage ([#486](https://github.com/tchapgouv/tchap-ios/issues/486))
- [Rooms list] Restore the room search ([#487](https://github.com/tchapgouv/tchap-ios/issues/487))
- Infinite loading wheel on logout ([#489](https://github.com/tchapgouv/tchap-ios/issues/489))
- List the direct rooms with the other rooms ([#490](https://github.com/tchapgouv/tchap-ios/issues/490))

🧱 Build

- Intégration d’Xcodegen dans le projet ([#391](https://github.com/tchapgouv/tchap-ios/issues/391))
- Utilisation de Towncrier pour générer le changelog ([#428](https://github.com/tchapgouv/tchap-ios/issues/428))


## Changes in Tchap 1.3.3 (2022-03-15) - Beta

Bug Fix:

    -   Files sent by Tchap Android 2 can't be read by Tchap iOS 1.2.2 #480

## Changes in Tchap 1.3.2 (2021-08-25)

Features/Improvements:

    -   Make certificates checking mode more flexible

## Changes in Tchap 1.3.1 (2021-08-23)

Features:

    -   Disable the room retention feature in Tchap (Prod) - It was
        enabled only in beta test program

## Changes in Tchap 1.3.0 (2021-05-31)

Features/Improvements:

    -   Enable the room retention feature in Tchap (Prod)
    -   Apply the new design of the Room header PR #383
    -   Apply the design for the specific Tchap Info room #384

## Changes in Tchap 1.2.3 (2022-03-14) - Prod

Bug Fix:

    -   Files sent by Tchap Android 2 can't be read by Tchap iOS 1.2.2 #480

## Changes in Tchap 1.2.2 (2021-08-25)

Features/Improvements:

    -   Make certificates checking mode more flexible

## Changes in Tchap 1.2.1 (2021-04-12)

Bug Fixes:

    -   Crash when the user selects \"forward\" on a selected message
    -   Favorite messages are not readable in dark mode
    -   Share extension: the rooms list are not readable in dark mode

## Changes in Tchap 1.2.0 (2021-03-24)

Features/Improvements:

    -   Design and implement favorite messages #292
    -   Public room creation: improve UI for agent.agent users #319
    -   \[Room retention\] Support unlimited room history (PR #367)
    -   Update the version used to trigger a clear cache during the
        application update (PR #367)
    -   Add a shortcut \"forward\" in the selected message options #353
    -   Room members: gray out the expired users #273
    -   Add the option to import the encryption keys in the Tchap
        settings #360

Bug Fixes:

    -   Crash on missing identity server information #357
    -   A discussion (1:1) is displayed by mistake as a private room
        opened to extern #356

## Changes in Tchap 1.1.1 (2020-12-18)

Features/Improvements:

    -   Enable the room access by link

Bug Fix:

    -   \[Room history\] The text input must be hidden when the user is
        not allowed to use it #348

## Changes in Tchap 1.1.0 (2020-11-19)

Bug Fixes:

    -   \[Room Preview\] unexpected failure on join: \"Not possible to
        join an empty room\" #346
    -   Wrong error message displayed to the external users when they
        try to join a room by link

## Changes in Tchap 1.0.30 (2020-11-17)

Features/Improvements:

    -   Update MatrixKit and MatrixSDK
    -   The room access by link is enabled only on Btchap

Bug Fixes:

    -   Tchap is stuck on the room preview whereas I joined with success
        the room #337
    -   E2EE: One time keys upload can try to upload the same key again
        (vector-im#3721)
    -   Fix unexpected 404 errors PR #344

## Changes in Tchap 1.0.29 (2020-10-28)

Features/Improvements:

    -   Private rooms: turn on the option to join on room's link #293
    -   Room preview: support the preview on shared room link #323
    -   Apply the new room creation design #317
    -   Apply the new design on the room avatar and name #332
    -   \[Room creation\] Do not override the power levels anymore #326
    -   \[Room access\] Improve the wordings related to the room link
        access #329
    -   Rename \"Salon public\" with \"Salon forum\" #333
    -   \[Room alias\] Harden the room aliases #328
    -   Force a clear cache on application update

## Changes in Tchap 1.0.28 (2020-09-03)

Bug Fix:

    -   Application may crash after the application update #321

## Changes in Tchap 1.0.27 (2020-08-28)

Bug Fix:

    -   The user is requested to login again after the application
        update #320

## Changes in Tchap 1.0.26 (2020-08-21)

Bug Fixes:

    -   Join a federated room failed PR #318
    -   The public room preview header is displayed under the navigation
        bar
    -   Room members count displayed in the title is wrong #291

## Changes in Tchap 1.0.25 (2020-08-14)

Bug Fixes:

    -   Remove delivered notifications when the user opens the related
        room
    -   Permalink error: \"Echec du chargement de la position dans
        l\'historique\" #315

## Changes in Tchap 1.0.24 (2020-08-14)

Features/Improvements:

    -   Add Notification Service Extension for Tchap and Btchap

    -   Update the project to build with Xcode11

    -   

        Rebase onto vector-im/riot-ios

            -   Get all changes from Riot until the commit: \'eb444a0\'
                (<https://github.com/dinsic-pim/tchap-ios/commit/a1fe3a645f57454033c0f36846564b4bbb60e6e2>)

    -   Set up the permalink option #272

    -   Handle the new email validation links from homeserver during a
        registration PR #311

    -   Update deployment target to iOS 11.0

Bug Fixes:

    -   Terms and Conditions are unavailable
    -   Present an activity indicator when the app is resumed on
        universal links PR #313
    -   The room of a permalink is not opened during a cold launch PR
        #314

## Changes in Tchap 1.0.23 (2020-06-10)

Features/Improvements:

    -   

        Rebase onto vector-im/riot-ios #277

            -   Get all changes from Riot 0.7.10 to Riot 0.10.4
                (<https://github.com/dinsic-pim/tchap-ios/pull/304/files#diff-db23dcd814354c954091a9b90dbfd92a>)

    -   Enable the device verification based on emojis string

    -   Disable key backup in the rebase version of the code #299

    -   Disable the message edition PR #305

    -   Disable the reactions

    -   Update the messages displayed during the request of a token by
        email #297

Bug Fixes:

    -   \[Device verification\] Only half of the key sharing requests
        are handled after verification #303
    -   The app may be stuck on the device verification screen #302
    -   Room members: the states of some members are wrong #253 (Force a
        clear cache on application update)
    -   Change history_visibility when a room is removed from the rooms
        directory #278

## Changes in Tchap 1.0.22 (2020-02-05)

Features/Improvements:

    -   Configure per-room retention period for messages #239 - Enabled
        only on Pre-prod.
    -   Order the room members by considering admin(s) first #284
    -   Room members: gray out the expired users #273

Bug Fixes:

    -   Room members count displayed in the title is wrong #291
    -   Room settings: the banned users are listed with their id instead
        of their display name #282

## Changes in Tchap 1.0.21 (2020-01-16)

Features/Improvements:

    -   Improve the warning dialog displayed before creating an external
        account
    -   Update the known instances list #283

## Changes in Tchap 1.0.20 (2019-12-17)

Features/Improvements:

    -   Set up the Tchap share extension #228
    -   Manage a minimum client version #214
    -   Update wording on limit exceeded error #276

Bug Fixes:

    -   Select an invite from the notifications doesn\'t not work #275
    -   The user lands in an empty room after selecting a notification
        #274

## Changes in Tchap 1.0.19 (2019-11-25)

Bug Fixes:

    -   Reply to: replace the matrix id with the member display name
        #236
    -   Join a federated public room failed #262
    -   KeyChain is not updated in case of Change Password #188
    -   Several DM invites may be sent to the same users #260

## Changes in Tchap 1.0.18 (2019-11-01)

Features/Improvements:

    -   Settings: Let the user decide to hide/show the join and leave
        events #216
    -   Update the pinned certificates list

Bug Fixes:

    -   Room members: the states of some members are wrong #253

## Changes in Tchap 1.0.17 (2019-09-23)

Features/Improvements:

    -   Add a mechanism to handle a potential cache clearing (if need)
        during the application update PR #252
    -   Force a cache clearing for this version

## Changes in Tchap 1.0.16 (2019-09-19)

Features/Improvements:

    -   Handle the strong password policy forced by the server #195
    -   Room creation: allow or not the external users to join the room
        #202
    -   Add a marker to indicate whether or not a room can be joined by
        external users #203
    -   The room admin is able to open the room to the external users
        #204
    -   Room members: invite new members by their email address #209
    -   Room members: remove the external users from the picker when
        they are not allowed to join #210
    -   Room members: remove the federated users from the picker when
        the room is not federated #222
    -   Improve the direct chat handling #235
    -   Expired account: update the dialog message when on new email has
        been requested #241
    -   Pin the new agent.externe certificate.
    -   Prompt the user before creating an external account #240
    -   Add room access info in the Room title #249

Bug Fixes:

    -   Room members: third-party invites can now be revoked PR #244
    -   Room member: some unexpected badges are displayed on invited
        members PR #246
    -   Room members: Some invited members don\'t have name.
    -   Do not use by default a member avatar for the room avatar #242

## Changes in Tchap 1.0.15 (2019-09-01)

Features/Improvements:

    -   Room attachments: allow to send files from the file system #215
    -   Force the email address in lower case #230
    -   Update MatrixKit and MatrixSDK

Bug Fixes:

    -   Handle correctly M_LIMIT_EXCEEDED error code #229

## Changes in Tchap 1.0.14 (2019-08-12)

Features/Improvements:

    -   Prompt external users before displaying their email in user
        directory #208
    -   Prompt the last room admin before letting him leave the room
        #218
    -   Allow the user to send a new invite to an external email address
        #220
    -   Add a splash screen

Bug Fixes:

    -   Preview on invited public room failed
    -   Error \"Profile isn\'t available\" just after logging in #219

## Changes in Tchap 1.0.13 (2019-06-28)

Features/Improvements:

    -   Pin the certificate of the [agent.externe]{.title-ref} instance.

## Changes in Tchap 1.0.12 (2019-06-18)

Features/Improvements:

    -   Support the account validity error #177
    -   The external users can now be hidden from the users directory
        search, show the option in settings #205
    -   Enable the proxy lookup use on Prod

Bug Fixes:

    -   Invite by email: The joined discussion is displayed like a
        \"salon\" #200

## Changes in Tchap 1.0.11 (2019-05-23)

Features/Improvements:

    -   Certificate pinning #165
    -   Support the proxy lookup PR #199

Bug Fixes:

    -   Registration - Accessibility: CGU checkbox is not accessible by
        Voiceover #194

## Changes in Tchap 1.0.10 (2019-04-24)

Features/Improvements:

    -   User Profile: add an option to hide the user from users
        directory search #167

Bug Fixes:

    -   Handle the Password AutoFill Workflow PR #187
    -   Flickering of the notification badges #189
    -   Room history: the most recent event is not displayed #136

## Changes in Tchap 1.0.9 (2019-04-09)

Features/Improvements:

    -   Registration: require that users agree to terms (EULA) #186
    -   Settings: Remove the phone number option #178

## Changes in Tchap 1.0.8 (2019-04-05)

Features/Improvements:

    -   Increase the minimum password length to 8 #179

Bug Fixes:

    -   Improve external users handing
    -   Fix a crash observed after a successful login

## Changes in Tchap 1.0.7 (2019-04-04)

Features/Improvements:

    -   Invite contact by email #166
    -   Restore the option to ignore a user from a Discussion #176

Bug Fixes:

    -   BugFix the account creation is stuck on email token submission
        PR #181

## Changes in Tchap 1.0.6 (2019-03-25)

Features/Improvements:

    -   Block invite to a deactivated account user #168
    -   Warn the user about the remote logout in case of a password
        change #164
    -   Hide the rooms created to invite some non-tchap contact by
        email. #172
    -   Configure the application for the extern users #139

Bug Fixes:

    -   Bug when leaving a room #162

## Changes in Tchap 1.0.5 (2019-03-08)

Features/Improvements:

    -   Turn on ITSAppUsesNonExemptEncryption flag

Bug Fixes:

    -   Public room: the avatar shape is wrong #152
    -   Room details: the attachments list is empty #151
    -   Room members: improve the contacts picker #140

## Changes in Tchap 1.0.4 (2019-02-25)

Features/Improvements:

    -   Private Room creation: change history visibility to \"invited\"
        #154
    -   Power level: a room member must be moderator to invite #155
    -   Adjust wording on bug report #160
    -   Keys sharing: remove the verification option #149
    -   Disable voip call #153

Bug Fixes:

    -   Push Notification: Tchap is not opened on the right room #150

## Changes in Tchap 1.0.3 (2019-02-08)

Features/Improvements:

    -   Setup Universal Links support for the registration process #119
    -   Registration: remove the polling mechanism on email validation
        #145
    -   Enable bug report #104
    -   Update TAC url
    -   Turn off \"ITSAppUsesNonExemptEncryption\" flag (until export
        compliance is reviewed)
    -   Enlarge room invite cell

Bug Fixes:

    -   Fix the flickering during unread messages badge rendering PR
        #148

## Changes in Tchap 1.0.2 (2019-01-30)

Features/Improvements:

    -   Turn on \"ITSAppUsesNonExemptEncryption\" flag

## Changes in Tchap 1.0.1 (2019-01-11)

Features/Improvements:

    -   Room history: update bubbles display #127
    -   Apply the Tchap tint color to the green icons #126

Bug Fixes:

    -   Unexpected logout #134
    -   Clear cache doesn\'t work properly #124
    -   room preview doesn\'t work #113
    -   The new joined discussions are displayed like a \"salon\" #122
    -   Rename the discussions left by the other member (\"Salon vide\")
        #128

## Changes in Tchap 1.0.0 (2018-12-14)

Features/Improvements:

    -   Set up push notifications in Tchap #108
    -   Antivirus - Media scan: Implement the MediaScanManager #77
    -   Antivirus Server: encrypt the keys sent to the antivirus server
        #105
    -   Support the new room creation by setting up avatar, name,
        privacy and participants #73
    -   Update Contacts cells display #88
    -   Show the voip option #103
    -   Update project by adding Btchap target PR #120
    -   Update color of days in rooms #115
    -   Encrypted room: Do not use the warning icon for the unverified
        devices #109
    -   Remove beta warning dialog when using encryption #110
    -   Accept unknown devices #111
    -   Configurer le dispositif de publication de l'application

Bug Fixes:

    -   Registration is stuck in the email validation step #117
    -   Matrix name when exporting keys #112

## Changes in Tchap 0.0.4 (2018-11-22)

Features/Improvements:

    -   Antivirus - Media download: support a potential anti-virus
        server #40
    -   Support the pinned rooms #16
    -   Room history: update input toolbar #92
    -   Update Rooms cells display #89
    -   Hide the voip option #90
    -   Disable matrix.to support #91
    -   Rebase onto vector-im/riot-ios
    -   Replace \"chat.xxx.gouv.fr\" url with \"matrix.xxx.gouv.fr\" #87

## Changes in Tchap 0.0.3 (2018-10-23)

Features/Improvements:

    -   Authentication: implement \"forgot password\" flow #38
    -   Contact selection: create a new discussion (if none) only when
        the user sends a message #41
    -   Update TAC link #72
    -   BugFix The display name of some users may be missing #69
    -   Design the room title view #68
    -   Encrypt event content for invited members #44
    -   Room history: remove the display of the state events (history
        access, encryption) #74
    -   Room creation: start/open a discussion with a tchap contact #18

## Changes in Tchap 0.0.2 (2018-09-28)

Features/Improvements:

    -   Authentication: implement the registration screens #4
    -   Add the search in the navigation bar #10
    -   Check the pending invites before creating new direct chat #13
    -   Open the existing direct chat on contact selection even if the
        contact has left it #14
    -   Re-invite left member on new message #15
    -   Set up the public rooms access #19
    -   Discussions settings are not editable #11
    -   Update room ("Salon") settings #42
    -   Room History: Disable membership event redaction #43

## Changes in Tchap 0.0.1 (2018-09-05)

Features/Improvements:

    -   Set up the new application Tchap-ios #1
    -   Replace Riot icons with the Tchap ones #2
    -   Disable/Hide the Home, Favorites and Communities tabs #6
    -   Authentication: Welcome screen #3
    -   Discover Tchap platform #22
    -   Authentication: implement the login screens #5
    -   Display all the joined rooms in the tab \"Conversations\" #7
    -   \"Contacts\": display all the known Tchap users #9
    -   User Profile is not editable #12
    -   Remove invite preview #20
