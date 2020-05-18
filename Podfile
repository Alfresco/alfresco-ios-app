source 'https://github.com/Alfresco/alfresco-private-podspecs-ios-sdk'
source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '12.0'
use_modular_headers!

target 'AlfrescoApp' do
    pod 'MBProgressHUD', '~> 1.0'
    pod 'Realm', '~>3.11'
    pod 'Firebase/Analytics'
    pod 'Firebase/Crashlytics'
    pod 'AlfrescoAuth'
    pod 'JWT'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'YES'
        end
    end
end 
