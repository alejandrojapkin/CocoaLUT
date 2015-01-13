Pod::Spec.new do |s|
  s.name         = "CocoaLUT"
  s.version      = begin; File.read('VERSION'); rescue; '9000.0.0'; end
  s.summary      = "LUTs (1D and 3D color lookup tables) for Cocoa applications."
  s.homepage     = "http://github.com/videovillage/CocoaLUT"
  s.license      = 'MIT'
  s.author       = { "Wil Gieseler" => "wil@wilgieseler.com", "Greg Cotten" => "greg@gregcotten.com"}
  s.source       = { :git => "https://github.com/videovillage/CocoaLUT.git", :tag => s.version }

  s.resource_bundle = {'TransferFunctionLUTs' => 'Assets/TransferFunctionLUTs/*.cube'}

  s.requires_arc = true
  s.source_files = 'Classes/**/*'
  s.public_header_files = 'Classes/**/*.h'
  s.frameworks = ['QuartzCore', 'GLKit']

  s.dependency 'RegExCategories'
  s.dependency 'M13OrderedDictionary'
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
