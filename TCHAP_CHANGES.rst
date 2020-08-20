Changes in Tchap 1.0.XX (2020-xx-xx)
===================================================
 
Bug Fixes:
 * Join a federated room failed PR #318
 * The public room preview header is displayed under the navigation bar

Changes in Tchap 1.0.25 (2020-08-14)
===================================================
 
Bug Fixes:
 * Remove delivered notifications when the user opens the related room
 * Permalink error: "Echec du chargement de la position dans l'historique" #315

Changes in Tchap 1.0.24 (2020-08-14)
===================================================

Features/Improvements:
 * Add Notification Service Extension for Tchap and Btchap
 * Update the project to build with Xcode11
 * Rebase onto vector-im/riot-ios
    - Get all changes from Riot until the commit: 'eb444a0' (https://github.com/dinsic-pim/tchap-ios/commit/a1fe3a645f57454033c0f36846564b4bbb60e6e2)
 * Set up the permalink option #272
 * Handle the new email validation links from homeserver during a registration PR #311
 * Update deployment target to iOS 11.0
 
Bug Fixes:
 * Terms and Conditions are unavailable
 * Present an activity indicator when the app is resumed on universal links PR #313
 * The room of a permalink is not opened during a cold launch PR #314
 
Changes in Tchap 1.0.23 (2020-06-10)
===================================================

Features/Improvements:
 * Rebase onto vector-im/riot-ios #277
    - Get all changes from Riot 0.7.10 to Riot 0.10.4 (https://github.com/dinsic-pim/tchap-ios/pull/304/files#diff-db23dcd814354c954091a9b90dbfd92a)
 * Enable the device verification based on emojis string
 * Disable key backup in the rebase version of the code #299
 * Disable the message edition PR #305
 * Disable the reactions
 * Update the messages displayed during the request of a token by email #297
 
Bug Fixes:
 * [Device verification] Only half of the key sharing requests are handled after verification #303
 * The app may be stuck on the device verification screen #302
 * Room members: the states of some members are wrong #253 (Force a clear cache on application update)
 * Change history_visibility when a room is removed from the rooms directory #278

Changes in Tchap 1.0.22 (2020-02-05)
===================================================

Features/Improvements:
 * Configure per-room retention period for messages #239 - Enabled only on Pre-prod.
 * Order the room members by considering admin(s) first #284
 * Room members: gray out the expired users #273
 
Bug Fixes:
 * Room members count displayed in the title is wrong #291
 * Room settings: the banned users are listed with their id instead of their display name #282

Changes in Tchap 1.0.21 (2020-01-16)
===================================================

Features/Improvements:
 * Improve the warning dialog displayed before creating an external account
 * Update the known instances list #283

Changes in Tchap 1.0.20 (2019-12-17)
===================================================

Features/Improvements:
 * Set up the Tchap share extension #228
 * Manage a minimum client version #214
 * Update wording on limit exceeded error #276

Bug Fixes:
 * Select an invite from the notifications doesn't not work #275
 * The user lands in an empty room after selecting a notification #274

Changes in Tchap 1.0.19 (2019-11-25)
===================================================

Bug Fixes:
 * Reply to: replace the matrix id with the member display name #236
 * Join a federated public room failed #262
 * KeyChain is not updated in case of Change Password #188
 * Several DM invites may be sent to the same users #260

Changes in Tchap 1.0.18 (2019-11-01)
===================================================

Features/Improvements:
 * Settings: Let the user decide to hide/show the join and leave events #216
 * Update the pinned certificates list

Bug Fixes:
 * Room members: the states of some members are wrong #253

Changes in Tchap 1.0.17 (2019-09-23)
===================================================

Features/Improvements:
 * Add a mechanism to handle a potential cache clearing (if need) during the application update PR #252
 * Force a cache clearing for this version

Changes in Tchap 1.0.16 (2019-09-19)
===================================================

Features/Improvements:
 * Handle the strong password policy forced by the server #195
 * Room creation: allow or not the external users to join the room #202
 * Add a marker to indicate whether or not a room can be joined by external users #203
 * The room admin is able to open the room to the external users #204
 * Room members: invite new members by their email address #209
 * Room members: remove the external users from the picker when they are not allowed to join #210
 * Room members: remove the federated users from the picker when the room is not federated #222
 * Improve the direct chat handling #235
 * Expired account: update the dialog message when on new email has been requested #241
 * Pin the new agent.externe certificate.
 * Prompt the user before creating an external account #240
 * Add room access info in the Room title #249
 
Bug Fixes:
 * Room members: third-party invites can now be revoked PR #244
 * Room member: some unexpected badges are displayed on invited members PR #246
 * Room members: Some invited members don't have name.
 * Do not use by default a member avatar for the room avatar #242

Changes in Tchap 1.0.15 (2019-09-01)
===================================================

Features/Improvements:
 * Room attachments: allow to send files from the file system #215
 * Force the email address in lower case #230
 * Update MatrixKit and MatrixSDK
 
Bug Fixes:
 * Handle correctly M_LIMIT_EXCEEDED error code #229
 
Changes in Tchap 1.0.14 (2019-08-12)
===================================================

Features/Improvements:
 * Prompt external users before displaying their email in user directory #208
 * Prompt the last room admin before letting him leave the room #218
 * Allow the user to send a new invite to an external email address #220
 * Add a splash screen
 
Bug Fixes:
 * Preview on invited public room failed
 * Error "Profile isn't available" just after logging in #219

Changes in Tchap 1.0.13 (2019-06-28)
===================================================

Features/Improvements:
 * Pin the certificate of the `agent.externe` instance.

Changes in Tchap 1.0.12 (2019-06-18)
===================================================

Features/Improvements:
 * Support the account validity error #177
 * The external users can now be hidden from the users directory search, show the option in settings #205
 * Enable the proxy lookup use on Prod
 
Bug Fixes:
 * Invite by email: The joined discussion is displayed like a "salon" #200

Changes in Tchap 1.0.11 (2019-05-23)
===================================================

Features/Improvements:
 * Certificate pinning #165
 * Support the proxy lookup PR #199
 
Bug Fixes:
 * Registration - Accessibility: CGU checkbox is not accessible by Voiceover #194

Changes in Tchap 1.0.10 (2019-04-24)
===================================================

Features/Improvements:
 * User Profile: add an option to hide the user from users directory search #167
 
Bug Fixes:
 * Handle the Password AutoFill Workflow PR #187
 * Flickering of the notification badges #189
 * Room history: the most recent event is not displayed #136

Changes in Tchap 1.0.9 (2019-04-09)
===================================================

Features/Improvements:
 * Registration: require that users agree to terms (EULA) #186
 * Settings: Remove the phone number option #178

Changes in Tchap 1.0.8 (2019-04-05)
===================================================

Features/Improvements:
 * Increase the minimum password length to 8 #179
 
Bug Fixes:
 * Improve external users handing
 * Fix a crash observed after a successful login

Changes in Tchap 1.0.7 (2019-04-04)
===================================================

Features/Improvements:
 * Invite contact by email #166
 * Restore the option to ignore a user from a Discussion #176
 
Bug Fixes:
 * BugFix the account creation is stuck on email token submission PR #181

Changes in Tchap 1.0.6 (2019-03-25)
===================================================

Features/Improvements:
 * Block invite to a deactivated account user #168
 * Warn the user about the remote logout in case of a password change #164
 * Hide the rooms created to invite some non-tchap contact by email. #172
 * Configure the application for the extern users #139
 
Bug Fixes:
 * Bug when leaving a room #162

Changes in Tchap 1.0.5 (2019-03-08)
===================================================

Features/Improvements:
 * Turn on ITSAppUsesNonExemptEncryption flag
 
Bug Fixes:
 * Public room: the avatar shape is wrong #152
 * Room details: the attachments list is empty #151
 * Room members: improve the contacts picker #140

Changes in Tchap 1.0.4 (2019-02-25)
===================================================

Features/Improvements:
 * Private Room creation: change history visibility to "invited" #154
 * Power level: a room member must be moderator to invite #155
 * Adjust wording on bug report #160
 * Keys sharing: remove the verification option #149
 * Disable voip call #153
 
Bug Fixes:
 * Push Notification: Tchap is not opened on the right room #150

Changes in Tchap 1.0.3 (2019-02-08)
===================================================

Features/Improvements:
 * Setup Universal Links support for the registration process #119
 * Registration: remove the polling mechanism on email validation #145
 * Enable bug report #104
 * Update TAC url
 * Turn off "ITSAppUsesNonExemptEncryption" flag (until export compliance is reviewed)
 * Enlarge room invite cell
 
Bug Fixes:
 * Fix the flickering during unread messages badge rendering PR #148

Changes in Tchap 1.0.2 (2019-01-30)
===================================================

Features/Improvements:
 * Turn on "ITSAppUsesNonExemptEncryption" flag

Changes in Tchap 1.0.1 (2019-01-11)
===================================================

Features/Improvements:
 * Room history: update bubbles display #127
 * Apply the Tchap tint color to the green icons #126
 
Bug Fixes:
 * Unexpected logout #134
 * Clear cache doesn't work properly #124
 * room preview doesn't work #113
 * The new joined discussions are displayed like a "salon" #122
 * Rename the discussions left by the other member ("Salon vide") #128

Changes in Tchap 1.0.0 (2018-12-14)
===================================================

Features/Improvements:
 * Set up push notifications in Tchap #108
 * Antivirus - Media scan: Implement the MediaScanManager #77
 * Antivirus Server: encrypt the keys sent to the antivirus server #105
 * Support the new room creation by setting up avatar, name, privacy and participants #73
 * Update Contacts cells display #88
 * Show the voip option #103
 * Update project by adding Btchap target PR #120
 * Update color of days in rooms #115
 * Encrypted room: Do not use the warning icon for the unverified devices #109
 * Remove beta warning dialog when using encryption #110
 * Accept unknown devices #111
 * Configurer le dispositif de publication de l’application
 
Bug Fixes:
 * Registration is stuck in the email validation step #117
 * Matrix name when exporting keys #112

Changes in Tchap 0.0.4 (2018-11-22)
===================================================

Features/Improvements:
 * Antivirus - Media download: support a potential anti-virus server #40
 * Support the pinned rooms #16
 * Room history: update input toolbar #92
 * Update Rooms cells display #89
 * Hide the voip option #90
 * Disable matrix.to support #91
 * Rebase onto vector-im/riot-ios
 * Replace "chat.xxx.gouv.fr" url with "matrix.xxx.gouv.fr" #87

Changes in Tchap 0.0.3 (2018-10-23)
===================================================

Features/Improvements:
 * Authentication: implement "forgot password" flow #38
 * Contact selection: create a new discussion (if none) only when the user sends a message #41
 * Update TAC link #72
 * BugFix The display name of some users may be missing #69
 * Design the room title view #68
 * Encrypt event content for invited members #44
 * Room history: remove the display of the state events (history access, encryption) #74
 * Room creation: start/open a discussion with a tchap contact #18

Changes in Tchap 0.0.2 (2018-09-28)
===================================================

Features/Improvements:
 * Authentication: implement the registration screens #4
 * Add the search in the navigation bar #10
 * Check the pending invites before creating new direct chat #13
 * Open the existing direct chat on contact selection even if the contact has left it #14
 * Re-invite left member on new message #15
 * Set up the public rooms access #19
 * Discussions settings are not editable #11
 * Update room (“Salon”) settings #42
 * Room History: Disable membership event redaction #43

Changes in Tchap 0.0.1 (2018-09-05)
===================================================
 
Features/Improvements:
 * Set up the new application Tchap-ios #1
 * Replace Riot icons with the Tchap ones #2
 * Disable/Hide the Home, Favorites and Communities tabs #6
 * Authentication: Welcome screen #3
 * Discover Tchap platform #22
 * Authentication: implement the login screens #5
 * Display all the joined rooms in the tab "Conversations" #7
 * "Contacts": display all the known Tchap users #9
 * User Profile is not editable #12
 * Remove invite preview #20
 