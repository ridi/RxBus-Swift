Pod::Spec.new do |s|
  s.name         = 'RxBus'
  s.version      = '1.3.2'
  s.summary      = 'Event bus framework supports sticky events and subscribers priority based on RxSwift.'
  s.homepage     = 'https://github.com/ridi/RxBus-Swift'
  s.authors      = { 'RIDI App Team' => 'app.team@ridi.com' }
  s.license      = 'MIT'
  s.swift_version = '5.6'
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'
  s.tvos.deployment_target = '11.0'
  s.source       = { :git => 'https://github.com/ridi/RxBus-Swift.git', :tag => s.version }
  s.source_files = 'Sources/RxBus/RxBus.swift'
  s.frameworks   = 'Foundation'
  s.dependency 'RxSwift', '~> 6.1.0'
end
