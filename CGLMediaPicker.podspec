Pod::Spec.new do |s|
  s.name             = "CGLMediaPicker"
  s.version          = "0.2.0"
  s.summary          = "The easiest way to let users get images into your app, handling permissions, the camera, and the photo library."
  s.description      = <<-DESC
                       CGLMediaPicker allows the user to choose a piece of multimedia of an array of types provided by the client, and runs a completion block once the user has either successfully chosen, or cancelled for some reason. Influenced by ClusterPrePermissions, with the goal of being lighter weight, and generally allowing clients to be more hands off.

                      It takes care of all permissions and UI, and is automatically retained in memory for as long as the user is actively choosing. There is no need for clients to maintain a reference.

                      It takes care of presenting the right photo picker or camera components. It takes care of asking for permissions, informing the user why permissions are lacking, when they're lacking, and sends them to Settings.app to take care of any problems they might need to.

                      In short, CGLMediaPicker lets you, the client, say: I would like the user to give me a piece of media. And then lets you sit back and wait for that media to arrive.
                       DESC
  s.homepage         = "https://github.com/chrisladd/CGLMediaPicker"
  s.screenshots     = "https://raw.githubusercontent.com/chrisladd/CGLMediaPicker/master/Screenshots/demo1.PNG", "https://raw.githubusercontent.com/chrisladd/CGLMediaPicker/master/Screenshots/demo2.PNG", "https://raw.githubusercontent.com/chrisladd/CGLMediaPicker/master/Screenshots/demo3.PNG"
  s.license          = 'MIT'
  s.author           = { "Chris Ladd" => "c.g.ladd@gmail.com" }
  s.source           = { :git => "https://github.com/chrisladd/CGLMediaPicker.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/chrisladd'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*'
  
  s.frameworks = 'UIKit', 'Photos', 'AssetsLibrary'

end
