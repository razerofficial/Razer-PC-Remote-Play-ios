# Uncomment the next line to define a global platform for your project
# platform :ios, '13.0'
project 'neuron.xcodeproj'
target 'neuron' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Razer PC Remote Play
  pod 'YYModel'
  pod 'FirebaseCrashlytics'
  pod 'SnapKit'
  pod 'RxSwift', '6.7.1'
  pod 'RxCocoa', '6.7.1'
  pod 'CocoaLumberjack/Swift', '3.8.5'
  pod 'IQKeyboardManager'
  
  #SwiftUI - Supports
  pod "Introspect"
  pod 'Kingfisher'

  target 'neuronTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'neuronUITests' do
    # Pods for testing
  end

end

post_install do |installer|
    installer.generated_projects.each do |project|
        project.targets.each do |target|
            target.build_configurations.each do |config|
                config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '13.0'
            end
        end
    end
end
