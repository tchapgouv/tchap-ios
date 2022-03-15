# Uncomment this line to define a global platform for your project
platform :ios, '11.0'

# Use frameworks to allow usage of pod written in Swift (like MatomoTracker)
use_frameworks!

# Different flavours of pods to MatrixKit. Can be one of:
# - a String indicating an official MatrixKit released version number
# - `:local` (to use Development Pods)
# - `{'kit branch name' => 'sdk branch name'}` to depend on specific branches of each repo
# - `{ {kit spec hash} => {sdk spec hash}` to depend on specific pod options (:git => …, :podspec => …) for each repo. Used by Fastfile during CI
#
# Warning: our internal tooling depends on the name of this variable name, so be sure not to change it
# $matrixKitVersion = '= 0.13.1'
# $matrixKitVersion = :local
# $matrixKitVersion = {'develop' => 'develop'}
$matrixKitVersion = {'dinum_prod' => 'dinum'}

########################################

case $matrixKitVersion
when :local
$matrixKitVersionSpec = { :path => '../matrix-ios-kit/MatrixKit.podspec' }
$matrixSDKVersionSpec = { :path => '../matrix-ios-sdk/MatrixSDK.podspec' }
when Hash # kit branch name => sdk branch name – or {kit spec Hash} => {sdk spec Hash}
kit_spec, sdk_spec = $matrixKitVersion.first # extract first and only key/value pair; key is kit_spec, value is sdk_spec
kit_spec = { :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => kit_spec.to_s } unless kit_spec.is_a?(Hash)
sdk_spec = { :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => sdk_spec.to_s } unless sdk_spec.is_a?(Hash)
$matrixKitVersionSpec = kit_spec
$matrixSDKVersionSpec = sdk_spec
when String # specific MatrixKit released version
$matrixKitVersionSpec = $matrixKitVersion
$matrixSDKVersionSpec = {}
end

# Method to import the right MatrixKit flavour
def import_MatrixKit
  pod 'MatrixSDK', $matrixSDKVersionSpec
  pod 'MatrixSDK/SwiftSupport', $matrixSDKVersionSpec
  pod 'MatrixSDK/JingleCallStack', $matrixSDKVersionSpec
  pod 'MatrixKit', $matrixKitVersionSpec
end

# Method to import the right MatrixKit/AppExtension flavour
def import_MatrixKitAppExtension
  pod 'MatrixSDK', $matrixSDKVersionSpec
  pod 'MatrixSDK/SwiftSupport', $matrixSDKVersionSpec
  pod 'MatrixKit/AppExtension', $matrixKitVersionSpec
end

########################################

abstract_target 'TchapPods' do

  pod 'GBDeviceInfo', '~> 6.4.0'
  pod 'Reusable', '~> 4.1'
  pod 'KeychainAccess', '~> 4.2.1'
 
  # Piwik for analytics
  pod 'MatomoTracker', '~> 7.2.2'

  pod 'RxSwift', '~> 5.1.1'

  # Remove warnings from "bad" pods
  pod 'OLMKit', :inhibit_warnings => true
  pod 'zxcvbn-ios', :inhibit_warnings => true
  pod 'HPGrowingTextView', :inhibit_warnings => true

  # Tools
  pod 'SwiftGen', '~> 6.3'
  pod 'SwiftLint', '~> 0.40.3'

  target "Tchap" do
    import_MatrixKit
    pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'
    pod 'KTCenterFlowLayout', '~> 1.3.1'
    pod 'ZXingObjC', '~> 3.6.5'
    pod 'SwiftBase32', '~> 0.9.0'
    pod 'SwiftJWT', '~> 3.5.3'
  end

  target "Btchap" do
    import_MatrixKit
    pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'
    pod 'KTCenterFlowLayout', '~> 1.3.1'
    pod 'ZXingObjC', '~> 3.6.5'
    pod 'SwiftBase32', '~> 0.9.0'
    pod 'SwiftJWT', '~> 3.5.3'
  end
    
  target "TchapShareExtension" do
      import_MatrixKitAppExtension
  end
  
  target "BtchapShareExtension" do
      import_MatrixKitAppExtension
  end

  target "TchapTests" do
    import_MatrixKit
  end
  
  target "TchapNSE" do
      import_MatrixKitAppExtension
  end

  target "BtchapNSE" do
      import_MatrixKitAppExtension
  end
end


post_install do |installer|
  installer.pods_project.targets.each do |target|

    target.build_configurations.each do |config|
      # Disable bitcode for each pod framework
      # Because the WebRTC pod (included by the JingleCallStack pod) does not support it.
      # Plus the app does not enable it
      config.build_settings['ENABLE_BITCODE'] = 'NO'
    end
  end
end
