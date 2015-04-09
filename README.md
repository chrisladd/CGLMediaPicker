# CGLMediaPicker

[![CI Status](http://img.shields.io/travis/Chris Ladd/CGLMediaPicker.svg?style=flat)](https://travis-ci.org/Chris Ladd/CGLMediaPicker)
[![Version](https://img.shields.io/cocoapods/v/CGLMediaPicker.svg?style=flat)](http://cocoapods.org/pods/CGLMediaPicker)
[![License](https://img.shields.io/cocoapods/l/CGLMediaPicker.svg?style=flat)](http://cocoapods.org/pods/CGLMediaPicker)
[![Platform](https://img.shields.io/cocoapods/p/CGLMediaPicker.svg?style=flat)](http://cocoapods.org/pods/CGLMediaPicker)

CGLMediaPicker allows the user to choose a piece of multimedia of an array of types provided by the client, and runs a completion block once the user has either successfully chosen, or cancelled for some reason. Influenced by ClusterPrePermissions, with the goal of being lighter weight, and generally allowing clients to be more hands off.
 
It takes care of all permissions and UI, and is automatically retained in memory for as long as the user is actively choosing. There is no need for clients to maintain a reference.

`ALAuthorizationStatus`? `UIImagePickerControllerDelegate`? `PHImageRequestOptions`? Who's got time for that $@*!?

CGLMediaPicker makes letting users provide photos as simple as creating a picker object, configuring it, and:

``` 
picker.completion = ^(UIImage *image, NSDictionary *info, NSError *error){
    // doing something nice with your user's chosen image
};
```

It takes care of presenting the right photo picker or camera components. It takes care of asking for permissions, informing the user why permissions are lacking, when they're lacking, and sends them to Settings.app to take care of any problems they might need to.
 
In short, CGLMediaPicker lets you, the client, say: I would like the user to give me a piece of media. And then lets you sit back and wait for that media to arrive.

Doesn't that sound nice?

<img src=/demo1.PNG width=200 />  <img src=/demo2.PNG width=200 />  <img src=/demo3.PNG width=200 /> 
 <img src=/demo4.PNG width=200 />  <img src=/demo5.PNG width=200 />  <img src=/demo6.PNG width=200 /> 


## Usage

```
__weak __typeof(self) weakSelf = self;
    
// initialize a new picker
CGLMediaPicker *picker = [[CGLMediaPicker alloc] initWithViewController:self];

// give it a series of inputs -- this will automatically be narrowed down by the picker to the inputs actually available on the user's device. e.g. if they don't have a camera
picker.inputs = @[CGLMediaPickerOptionCamera, CGLMediaPickerOptionPhotoLibrary, CGLMediaPickerOptionUserLastPhoto];

// tell the user a little about what you'll use their photos for
picker.permissionMessage = NSLocalizedString(@"We'll use your photos to set the background to this view controller.", nil);

// add a completion. note that you don't have to maintain a reference to the picker -- it's stored internally by the class until the user has finished interacting with it.
picker.completion = ^(UIImage *image, NSDictionary *info, NSError *error){
    if (image) {
        weakSelf.imageView.image = image;
    }
};
    
// lastly, go ahead and pick. This will present your options to the user.
[picker pick];

```

## Installation

CGLMediaPicker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "CGLMediaPicker"
```

## Author

Chris Ladd, c.g.ladd@gmail.com

## License

CGLMediaPicker is available under the MIT license. See the LICENSE file for more info.
