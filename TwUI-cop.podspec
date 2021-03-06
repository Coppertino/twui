Pod::Spec.new do |s|
  s.name           = "TwUI-cop"
  s.version        = "0.13"
  s.summary        = "Fork of TwUI - a UI framework for Mac based on Core Animation."
  s.description    = "TwUI is a hardware accelerated UI framework for Mac, inspired by UIKit. It enables:\n"\
                     "- GPU accelerated rendering backed by CoreAnimation.\n"\
                     "- Simple model/view/controller development familiar to iOS developers."

  s.homepage       = "https://github.com/Coppertino/twui"
  s.author         = { "Twitter, Inc." => "opensource@twitter.com",
                       "GitHub, Inc." => "support@github.com" }
  s.license        = { :type => 'Apache License, Version 2.0' }
  s.source         = { :git => "https://github.com/Coppertino/twui.git", :tag => "#{s.version}" }

  s.platform       = :osx, '10.8'
  s.requires_arc   = true
  s.frameworks     = 'ApplicationServices', 'QuartzCore', 'Cocoa'
  
  s.source_files   = 'lib/{UIKit,Support}/*.{h,m}'
  s.exclude_files  = '**/*{TUIAccessibilityElement}*'
  
end
