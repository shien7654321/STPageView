Pod::Spec.new do |s|

  s.name         = "STPageView"
  s.version      = "0.0.4"
  s.summary      = "A paging view."
  s.homepage     = "https://github.com/shien7654321/STPageView"
  s.author       = { "Suta" => "shien7654321@163.com" }
  s.source       = { :git => "https://github.com/shien7654321/STPageView.git", :tag => s.version.to_s }
  s.platform     = :ios, "8.0"
  s.requires_arc = true
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.frameworks   = "Foundation", "UIKit"
  s.source_files = "STPageView/*.{swift}"
  s.compiler_flags = "-fmodules"
  s.pod_target_xcconfig = { 'SWIFT_VERSION' => '4.1' }
  s.description    = <<-DESC
  STPageView is a paging view.
                       DESC

end
