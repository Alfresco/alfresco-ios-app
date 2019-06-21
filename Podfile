platform :ios, '10.3'

target 'AlfrescoApp' do
    pod 'MBProgressHUD', '~> 1.0'
    pod 'NJKWebViewProgress', '~> 0.2'
    pod 'HockeySDK', '~> 3.8'
    pod 'Google/Analytics'
    pod 'Realm', '~>3.11'
    pod 'Flurry-iOS-SDK/FlurrySDK' #Analytics Pod
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'YES'
        end
    end
end 
