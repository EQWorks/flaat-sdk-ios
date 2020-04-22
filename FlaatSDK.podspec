Pod::Spec.new do |s|
  s.name             = 'FlaatSDK'
  s.version          = '0.1.0'
  s.summary          = 'Flaat SDK provides a set of APIs to support COVID-19 contact tracing in any app'
  s.homepage         = 'https://github.com/eqworks/flaat-sdk-ios'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'EQ-Works' => 'dilshank@eqworks.com' }
  s.source           = { :git => 'https://github.com/eqworks/flaat-sdk-ios.git', :tag => s.version.to_s }

  s.ios.deployment_target = '12.0'
  s.swift_versions = ['5.1', '5.2']
  s.source_files = 'FlaatSDK/Classes/**/*'
  
  # s.resource_bundles = {
  #   'FlaatSDK' => ['FlaatSDK/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
