spec.name = "ZeitSatTrack"
  spec.version = "1.0.0"
spec.summary = "Satellite Tracking Library."
  spec.homepage = "https://github.com/dhmspector/ZeitSatTrack"
  spec.license = { type: 'Apache 2.0', file: 'LICENSE' }
  spec.authors = { "David Specgtor" => 'spector@zeitgeist.com' }
  spec.social_media_url = "http://twitter.com/dhmspector"

  spec.platform = :ios, "10.0"
  spec.requires_arc = true
  spec.source = { git: "https://github.com/dhmspector/RGB.git", tag: "v#{spec.version}", submodules: true }
  spec.source_files = "ZeitTrackLib/**/*.{h,swift}"

end
