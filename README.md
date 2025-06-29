# Tchap iOS

![GitHub release (latest by date)](https://img.shields.io/github/v/release/dinsic-pim/tchap-ios)
![badge-languages](https://img.shields.io/badge/languages-Swift%20%7C%20ObjC-orange.svg)
[![Swift 5.x](https://img.shields.io/badge/Swift-5.x-orange)](https://developer.apple.com/swift)
[![Build status](https://badge.buildkite.com/cc8f93e32da93fa7c1172398bd8af66254490567c7195a5f3f.svg?branch=develop)](https://buildkite.com/matrix-dot-org/element-ios/builds?branch=develop)
[![Weblate](https://translate.riot.im/widgets/riot-ios/-/svg-badge.svg)](https://translate.riot.im/engage/riot-ios/?utm_source=widget)
[![codecov](https://codecov.io/gh/element-hq/element-ios/branch/develop/graph/badge.svg?token=INNm5o6XWg)](https://codecov.io/gh/element-hq/element-ios)
[![Quality Gate Status](https://sonarcloud.io/api/project_badges/measure?project=element-ios&metric=alert_status)](https://sonarcloud.io/summary/new_code?id=element-ios)
[![Bugs](https://sonarcloud.io/api/project_badges/measure?project=element-ios&metric=bugs)](https://sonarcloud.io/summary/new_code?id=element-ios)
[![Vulnerabilities](https://sonarcloud.io/api/project_badges/measure?project=element-ios&metric=vulnerabilities)](https://sonarcloud.io/summary/new_code?id=element-ios)
[![Element iOS Matrix room #element-ios:matrix.org](https://img.shields.io/matrix/element-ios:matrix.org.svg?label=%23element-ios:matrix.org&logo=matrix&server_fqdn=matrix.org)](https://matrix.to/#/#element-ios:matrix.org)
![GitHub](https://img.shields.io/github/license/element-hq/element-ios)
[![Twitter URL](https://img.shields.io/twitter/url?label=Element&url=https%3A%2F%2Ftwitter.com%2Felement_hq)](https://twitter.com/element_hq)

Tchap iOS is an iOS [Matrix](https://matrix.org/) client. It is based on [MatrixSDK](https://github.com/matrix-org/matrix-ios-sdk).

<p align="center">  
  <a href=https://apps.apple.com/fr/app/tchap/id1446253779?mt=8>
  <img alt="Download on the app store" src="https://linkmaker.itunes.apple.com/images/badges/en-us/badge_appstore-lrg.svg" width=160>
  </a>
</p>

## Beta testing 

You can try last beta build by accessing our [TestFlight Public Link](https://testflight.apple.com/join/1kphRbLz).

## Build instructions

If you have already everything installed, opening the project workspace in Xcode should be as easy as:

```
$ xcodegen                  # Create the xcodeproj with all project source files
$ pod install               # Create the xcworkspace with all project dependencies
$ open Tchap.xcworkspace     # Open Xcode
```

Else, you can visit our [installation guide](./INSTALL.md). This guide also offers more details and advanced usage like using [MatrixSDK](https://github.com/matrix-org/matrix-ios-sdk) in its development version.

## Contributing

If you want to contribute to Tchap iOS code please refer to the [contribution guide](CONTRIBUTING.md).

## Support

When you are experiencing an issue on Tchap iOS, please first search in [GitHub issues](https://github.com/dinsic-pim/tchap-ios/issues). Otherwise feel free to create a GitHub issue if you encounter a bug or a crash, by explaining clearly in detail what happened. You can also perform bug reporting (Rageshake) from the Tchap application by shaking your phone or going to the application settings. This is especially recommended when you encounter a crash.

## Copyright & License

Copyright (c) 2014-2017 OpenMarket Ltd  
Copyright (c) 2017 Vector Creations Ltd  
Copyright (c) 2017-2025 New Vector Ltd

Copyright (c) 2024-2025, Direction interministérielle du numérique

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.

This software is dual licensed by New Vector Ltd (Element). It can be used either:
(1) for free under the terms of the GNU Affero General Public License (as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version); OR

(2) under the terms of a paid-for Element Commercial License agreement between you and Element (the terms of which may vary depending on what you and Element have agreed to).

Unless required by applicable law or agreed to in writing, software distributed under the Licenses is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the Licenses for the specific language governing permissions and limitations under the Licenses.
