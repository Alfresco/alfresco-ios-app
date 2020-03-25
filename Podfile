platform :ios, '10.3'

target 'AlfrescoApp' do
    pod 'MBProgressHUD', '~> 1.0'
    pod 'NJKWebViewProgress', '~> 0.2'
    pod 'Realm', '~>3.11'
    pod 'Firebase/Analytics'
    pod 'Firebase/Crashlytics'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'YES'
        end
    end
end 
