//
//  CGLViewController.m
//  CGLMediaPicker
//
//  Created by Chris Ladd on 04/08/2015.
//  Copyright (c) 2014 Chris Ladd. All rights reserved.
//

#import "CGLViewController.h"
#import <CGLMediaPicker/CGLMediaPicker.h>

@interface CGLViewController ()
@property (nonatomic) UIImageView *imageView;
@end

@implementation CGLViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.imageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    self.imageView.contentMode = UIViewContentModeScaleAspectFill;
    self.imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.imageView];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:NSLocalizedString(@"Pick Media", nil) forState:UIControlStateNormal];
    button.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    button.frame = self.view.bounds;
    [self.view addSubview:button];
    
    [button addTarget:self action:@selector(pickMedia:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)pickMedia:(id)sender {
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
    
    // lastly, go ahead and pick
    [picker pick];
}

@end
