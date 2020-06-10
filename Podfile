# Uncomment this line to define a global platform for your project
platform :ios, '10.0'

# Use frameworks to allow usage of pod written in Swift (like MatomoTracker)
use_frameworks!


# Different flavours of pods to MatrixKit
# The current MatrixKit pod version
#$matrixKitVersion = '0.11.3'

# The develop branch version
#$matrixKitVersion = 'develop'

# The develop branch version
$matrixKitVersion = 'dinum'

# The one used for developing both MatrixSDK and MatrixKit
# Note that MatrixSDK must be cloned into a folder called matrix-ios-sdk next to the MatrixKit folder
#$matrixKitVersion = 'local'


# Method to import the right MatrixKit flavour
def import_MatrixKit
    if $matrixKitVersion == 'local'
        pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixSDK/SwiftSupport', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixSDK/JingleCallStack', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixKit', :path => '../matrix-ios-kit/MatrixKit.podspec'
    else
        if $matrixKitVersion == 'develop'
            pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixSDK/SwiftSupport', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixSDK/JingleCallStack', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixKit', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'
        else
            if $matrixKitVersion == 'dinum'
                pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'dinum'
                pod 'MatrixSDK/SwiftSupport', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'dinum'
                pod 'MatrixSDK/JingleCallStack', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'dinum'
                pod 'MatrixKit', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'dinum'
            else
                pod 'MatrixKit', $matrixKitVersion
                pod 'MatrixSDK/SwiftSupport'
                pod 'MatrixSDK/JingleCallStack'
            end
        end
    end 
end

# Method to import the right MatrixKit/AppExtension flavour
def import_MatrixKitAppExtension
    if $matrixKitVersion == 'local'
        pod 'MatrixSDK', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixSDK/SwiftSupport', :path => '../matrix-ios-sdk/MatrixSDK.podspec'
        pod 'MatrixKit/AppExtension', :path => '../matrix-ios-kit/MatrixKit.podspec'
    else
        if $matrixKitVersion == 'develop'
            pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixSDK/SwiftSupport', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'develop'
            pod 'MatrixKit/AppExtension', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'develop'
        else
            if $matrixKitVersion == 'dinum'
                pod 'MatrixSDK', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'dinum'
                pod 'MatrixSDK/SwiftSupport', :git => 'https://github.com/matrix-org/matrix-ios-sdk.git', :branch => 'dinum'
                pod 'MatrixKit/AppExtension', :git => 'https://github.com/matrix-org/matrix-ios-kit.git', :branch => 'dinum'
            else
                pod 'MatrixKit/AppExtension', $matrixKitVersion
                pod 'MatrixSDK/SwiftSupport'
            end
        end
    end 
end

abstract_target 'TchapPods' do

    pod 'GBDeviceInfo', '~> 6.3.0'
    pod 'Reusable', '~> 4.1'
    pod 'SwiftUTI', :git => 'https://github.com/speramusinc/SwiftUTI.git', :branch => 'master'

    # Matomo for analytics
    pod 'MatomoTracker', '~> 7.2.0'
    
    pod 'RxSwift', '~> 4.3'

    # Remove warnings from "bad" pods
    pod 'OLMKit', :inhibit_warnings => true
    pod 'cmark', :inhibit_warnings => true
    pod 'zxcvbn-ios'
    
    # Build tools
    pod 'SwiftGen', '~> 6.1'
    pod 'SwiftLint', '~> 0.36.0'

    target "Tchap" do
        import_MatrixKit
        pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'
    end
	
    target "Btchap" do
        import_MatrixKit
        pod 'DGCollectionViewLeftAlignFlowLayout', '~> 1.0.4'
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
    
end


post_install do |installer|
    installer.pods_project.targets.each do |target|

        # Disable bitcode for each pod framework
        # Because the WebRTC pod (included by the JingleCallStack pod) does not support it.
        # Plus the app does not enable it
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'NO'
            
            # Force the min IOS deployment target for matrixKit
            if target.name.include? 'MatrixKit'
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
            end
            
            # Force the min IOS deployment target for matrixSDK
            if target.name.include? 'MatrixSDK'
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '10.0'
            end
            
            # Force SwiftUTI Swift version to 5.0 (as there is no code changes to perform for SwiftUTI fork using Swift 4.2)
            if target.name.include? 'SwiftUTI'
                config.build_settings['SWIFT_VERSION'] = '5.0'
            end
        end
    end
end

