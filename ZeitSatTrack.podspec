Pod::Spec.new do |s|

  s.name         = "ZeitSatTrack"
  s.version      = "0.9.0"
  s.summary      = "A Satellite Tracking Library for Swift"

  s.description  = <<-DESC
ZeitSatTrack is a satellite tracking library written in Swift.  It reads in collections of Two line Element (TLE) Files 
and provdes a number of different mecahisms for getting satellite positioning data (lat/lon, alititude) and other info useful to an earthbound observer.
                   DESC

  s.homepage     = "https://github.com/dhmspector/ZeitSatTrack"
  # s.screenshots  = "www.example.com/screenshots_1.gif", "www.example.com/screenshots_2.gif"


  s.license      = "Apache 2.0"
  s.author             = { "David Spector" => "spector@zeitgeist.com" }
  s.social_media_url   = "http://twitter.com/dhmpector"

  s.platform     = :ios, "10.0"
  # s.osx.deployment_target = "10.12"
  s.source       = { :git => "https://github.com/dhmspector/ZeitSatTrack.git", :commit => "359bb3a048804b6be1feed92ad6833673121ddd6" }


  # ――― Source Code ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  CocoaPods is smart about how it includes source code. For source files
  #  giving a folder will include any swift, h, m, mm, c & cpp files.
  #  For header files it will include any header in the folder.
  #  Not including the public_header_files will make all headers public.
  #

  s.source_files  = "ZeitSatTrackLib", "ZeitSatTrackLib/**/*.{h,swift}"
  #s.exclude_files = "Classes/Exclude"
  # s.public_header_files = "Classes/**/*.h"
  s.resources = "DataSources/satellite-tle-sources.json"


  # ――― Project Linking ―――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  Link your library with frameworks, or libraries. Libraries do not include
  #  the lib prefix of their name.
  #

  # s.framework  = "SomeFramework"
  # s.frameworks = "SomeFramework", "AnotherFramework"

  # s.library   = "iconv"
  # s.libraries = "iconv", "xml2"


  # ――― Project Settings ――――――――――――――――――――――――――――――――――――――――――――――――――――――――― #
  #
  #  If your library depends on compiler flags you can set them in the xcconfig hash
  #  where they will only apply to your library. If you depend on other Podspecs
  #  you can include multiple dependencies to ensure it works.

  # s.requires_arc = true

  # s.xcconfig = { "HEADER_SEARCH_PATHS" => "$(SDKROOT)/usr/include/libxml2" }
  # s.dependency "JSONKit", "~> 1.4"

end
