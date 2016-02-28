#
# Be sure to run `pod lib lint ExpandingMenu.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "ExpandingMenu"
  s.version          = "0.1.3"
  s.summary          = "A mune button expanding vertical."

# This description is used to generate tags and improve search results.
#   * Think: What does it do? Why did you write it? What is the focus?
#   * Try to keep it short, snappy and to the point.
#   * Write the description between the DESC delimiters below.
#   * Finally, don't worry about the indent, CocoaPods strips it!  
  s.description      = <<-DESC
                       This library provides a global menu button.
                       DESC

  s.homepage         = "https://github.com/monoqlo/ExpandingMenu"
  # s.screenshots     = "www.example.com/screenshots_1", "www.example.com/screenshots_2"
  s.license          = 'MIT'
  s.author           = { "monoqlo" => "monoqlo44@gmail.com" }
  s.source           = { :git => "https://github.com/monoqlo/ExpandingMenu.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/monoqlo'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'ExpandingMenu/Classes/*.swift'
  s.resource_bundles = {
    'ExpandingMenu' => ['ExpandingMenu/Assets/Sounds/*']
  }

  s.frameworks = 'QuartzCore','AudioToolBox'
end
