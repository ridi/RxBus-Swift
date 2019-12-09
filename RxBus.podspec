Pod::Spec.new do |s|
  s.name         = 'RxBus'
  s.version      = '1.2.0'
  s.summary      = 'Event bus framework supports sticky events and subscribers priority based on RxSwift.'
  s.homepage     = 'https://github.com/ridi/RxBus-Swift'
  s.authors      = { 'Ridibooks Viewer Team' => 'viewer.team@ridi.com' }
  s.license      = 'MIT'
  s.swift_version = '5.0'
  s.ios.deployment_target = '8.0'
  s.osx.deployment_target = '10.10'
  s.tvos.deployment_target = '9.0'
  s.source       = { :git => 'https://github.com/ridi/RxBus-Swift.git', :tag => s.version }
  s.source_files = 'RxBus/RxBus.swift'
  s.frameworks   = 'Foundation'
  s.dependency 'RxSwift', '~> 5.0'
end
