Pod::Spec.new do |s|
  s.name         = "TUMessagePackSerialization"
  s.version      = "0.1.0"
  s.summary      = "Native, efficient MessagePack reading and writing."
  s.homepage     = "https://github.com/davbeck/TUMessagePackSerialization"
  s.license      = 'MIT'
  s.author       = { "David Beck" => "code@davidbeck.co" }
  s.source       = { :git => "https://github.com/davbeck/TUMessagePackSerialization.git", :tag => s.version.to_s }

  s.ios.platform = '6.0'
  s.osx.platform = '10.7'
  s.requires_arc = true

  s.source_files = 'Classes'

  s.public_header_files = 'Classes/*.h'
end
