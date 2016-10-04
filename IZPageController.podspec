#
# Be sure to run `pod lib lint IZPageController.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'IZPageController'
  s.version          = '0.2.0'
  s.summary          = 'Used to create easily scrolled views that snap to place.'

  s.description      = <<-DESC
This library is a simple alternative to UIPageController that alows for multiple views to be placed next to each other that can be viewed by scrolling left and right, the views will snap into place. It also supports Landscape viewing with two pages visible with the same snapping feature.
                       DESC

  s.homepage         = 'https://github.com/izeni-team/IZPageController'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Taylor' => 'tallred@izeni.com' }
  s.source           = { :git => 'https://github.com/izeni-team/IZPageController.git', :tag => s.version.to_s }

  s.ios.deployment_target = '9.0'

  s.source_files = 'IZPageController/Classes/**/*'
  
  # s.resource_bundles = {
  #   'IZPageController' => ['IZPageController/Assets/*.png']
  # }

  # s.public_header_files = 'Pod/Classes/**/*.h'
  # s.frameworks = 'UIKit', 'MapKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
