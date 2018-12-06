#
# Be sure to run `pod lib lint CSSTracker.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'CSSTracker'
  s.version          = '0.1.5'
  s.summary          = 'A short description of CSSTracker.'

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!

  s.description      = <<-DESC
TODO: Add long description of the pod here.
                       DESC

  s.homepage         = 'https://github.com/sangshenya/CSSTracker'
  # s.screenshots     = 'www.example.com/screenshots_1', 'www.example.com/screenshots_2'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'sangshenya' => 'sangshen@ecook.cn' }
  s.source           = { :git => 'https://github.com/sangshenya/CSSTracker.git', :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/<TWITTER_USERNAME>'

  s.ios.deployment_target = '8.0'
  
#  s.xcconfig = {'OTHER_LDFLAGS' => '-ObjC'}

#  s.libraries = 'z'

s.source_files = 'CSSTracker/Classes/*.{h,m}'

  s.dependency 'CSSKit'
  s.dependency 'CSSDeviceInfoTool'
  s.dependency 'CSSNetworkClient'
  
#  s.dependency 'MCLocationManager'

  s.ios.vendored_frameworks = 'CSSTracker/Classes/*.framework'

#s.vendored_frameworks = 'CSSTracker/Classes/Framework/*.framework'

#  s.subspec 'Crash' do |ss|
#      ss.source_files = 'CSSTracker/Classes/Crash/**/*'
#  end

#  s.subspec 'Hook' do |ss|
#      ss.source_files = 'CSSTracker/Classes/Hook/**/*'
#  end

#  s.subspec 'HttpSend' do |ss|
#      ss.source_files = 'CSSTracker/Classes/HttpSend/**/*'
#  end

  s.subspec 'Persistence' do |ss|
      ss.source_files = 'CSSTracker/Classes/Persistence/**/*'
  end
  
#  s.subspec 'Framework' do |ss|
#
#  end

#  s.subspec 'Tracker' do |ss|
#      ss.source_files = 'CSSTracker/Classes/Tracker/**/*'
#  end

  # s.resource_bundles = {
  #   'CSSTracker' => ['CSSTracker/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
