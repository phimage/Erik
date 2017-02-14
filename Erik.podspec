Pod::Spec.new do |s|

  # ―――  Spec Metadata  ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.name         = "Erik"
  s.version      = "2.0.2"
  s.summary      = "A headless browser written in Swift"
  s.description  = <<-DESC
                    Erik is an headless browser based on WebKit and HTML parser Kanna.
                    An headless browser allow to run functional tests, to access and manipulate webpages.
                   DESC
  s.homepage     = "https://github.com/phimage/Erik"

  # ―――  Spec License  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.license      = "MIT"

  # ――― Author Metadata  ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.author             = { "phimage" => "eric.marchand.n7@gmail.com" }

  # ――― xcconfig ――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.xcconfig      = {
                        'HEADER_SEARCH_PATHS' => '$(SDKROOT)/usr/include/libxml2',
                        'SWIFT_INCLUDE_PATHS' => '$(SRCROOT)/Kanna/Modules'
                      }
  # ――― Platform Specifics ――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.ios.deployment_target = '9.0'
  s.osx.deployment_target = '10.10'

  # ――― Source Location ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  s.source       = { :git => "https://github.com/phimage/Erik.git", :tag => s.version }

  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #

  s.default_subspec = 'Core'

  s.subspec "Core" do  |sp|
    sp.source_files = "Sources/*.swift"
  end

  s.subspec "Future" do  |sp|
    sp.source_files = "Sources/Future/*.swift"
    sp.dependency 'Erik/Core'
    sp.dependency 'BrightFutures'
  end

  s.dependency 'Kanna'

end
