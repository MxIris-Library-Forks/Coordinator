Pod::Spec.new do |s|
  s.name         = 'Coordinator'
  s.version      = '6.5'
  s.summary      = 'Advanced Swift implementation of (Application) Coordinator software design pattern.'
  s.description  = 'It implements a mechanism to allow custom messaging between any UIView, UIViewController and Coordinator, regardless of where in the hierarchy they are. Thus it side-steps the need for delegates all over your code. It simplifies testing and allows creation of self-contained visual boxes that do one thing and don’t care where are they embedded or presented.'
  s.homepage     = 'https://github.com/radianttap/Coordinator'
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author       = { 'Aleksandar Vacić' => 'radianttap.com' }
  s.social_media_url   			= "https://twitter.com/radiantav"
  s.ios.deployment_target 		= "12.1"
  s.tvos.deployment_target 		= "12.0"
  s.source       = { :git => "https://github.com/radianttap/Coordinator.git" }
  s.source_files = 'Coordinator/*.swift'
  s.frameworks   = 'UIKit'

  s.swift_version  = '5.0'
end
