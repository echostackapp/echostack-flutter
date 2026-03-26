Pod::Spec.new do |s|
  s.name             = 'echostack_plugin'
  s.version          = '1.0.0'
  s.summary          = 'EchoStack mobile attribution SDK for Flutter'
  s.description      = 'Flutter plugin wrapping native EchoStack iOS SDK for mobile attribution.'
  s.homepage         = 'https://echostack.app'
  s.license          = { :type => 'MIT' }
  s.author           = 'EchoStack'
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.platform         = :ios, '14.0'
  s.swift_version    = '5.9'

  s.dependency 'Flutter'
  # Native EchoStack SDK is embedded via SPM in the host app
end
