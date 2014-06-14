Pod::Spec.new do |s|
  s.name         = "CocoaLUT"
  s.version      = File.read('VERSION')
  s.summary      = "LUT (3D lookup tables) for Cocoa applications."
  s.homepage     = "http://github.com/wilg/CocoaLUT"
  s.license      = 'MIT'
  s.author       = { "Wil Gieseler" => "wil@wilgieseler.com", "Greg Cotten" => "greg@gregcotten.com"}
  s.source       = { :git => "https://github.com/wilg/CocoaLUT.git", :tag => s.version.to_s }

  s.requires_arc = true
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.frameworks = ['QuartzCore', 'GLKit']

  s.dependency 'RegExCategories'
  s.dependency 'M13OrderedDictionary'
  s.dependency 'SAMCubicSpline'
  s.dependency 'XMLDictionary'

  # iOS
  s.ios.frameworks = 'UIKit'
  s.ios.exclude_files = 'Classes/osx'
  s.ios.deployment_target = '7.0'

  # OS X
  s.osx.frameworks = 'AppKit'
  s.osx.exclude_files = 'Classes/ios'
  s.osx.deployment_target = '10.7'

end
