# Tchap iOS

![GitHub release (latest by date)](https://img.shields.io/github/v/release/dinsic-pim/tchap-ios)
![badge-languages](https://img.shields.io/badge/languages-Swift%20%7C%20ObjC-orange.svg)
[![Swift 5.x](https://img.shields.io/badge/Swift-5.x-orange)](https://developer.apple.com/swift)
![GitHub](https://img.shields.io/github/license/dinsic-pim/tchap-ios)

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
Copyright (c) 2017-2021 New Vector Ltd

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this work except in compliance with the License. You may obtain a copy of the License in the [LICENSE](LICENSE) file, or at:

[http://www.apache.org/licenses/LICENSE-2.0](http://www.apache.org/licenses/LICENSE-2.0)

Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.
