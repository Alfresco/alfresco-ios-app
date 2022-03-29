source 'https://cdn.cocoapods.org/'

platform :ios, '12.0'
use_modular_headers!

target 'AlfrescoApp' do
    pod 'MBProgressHUD', '~> 1.0'
    pod 'Realm'
    pod 'Firebase/Analytics'
    pod 'Firebase/Crashlytics'
    pod 'AlfrescoAuth', '~> 0'
    pod 'JWT'
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['ENABLE_BITCODE'] = 'YES'
        end
    end
end 
