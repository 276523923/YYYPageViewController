#
# Be sure to run `pod lib lint YYYPageViewController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name         = 'YYYPageViewController'
  s.version      = '1.0.1'
  s.summary      = 'YYYPageViewController'

  s.description  = 'YYYPageViewController 多个viewController 控制器'

  s.homepage         = 'https://github.com/276523923/YYYPageViewController.git'
  s.license          = { :type => "MIT", :file => "LICENSE" }
  s.author           = { '276523923@qq.com' => '276523923@qq.com' }

  s.source       = { :git => 'https://github.com/276523923/YYYPageViewController.git', :tag => s.version.to_s }
  s.ios.deployment_target = '8.0'
  s.requires_arc = true

  # s.static_framework = true

  s.source_files  = "YYYPageViewController/Classes/**/*.{h,m}"
  s.public_header_files = "YYYPageViewController/Classes/**/*.h"

  # s.resources = "YYYPageViewController/Assets/**/*"
  # s.resource_bundles = {
  #   YYYPageViewController => ["YYYPageViewController/Assets/**/*"]
  # }
  s.dependency "YYYWeakProxy"

  # s.dependency ""
end
