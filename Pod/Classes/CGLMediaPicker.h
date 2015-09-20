//
//  CGLMediaPicker.h
//
//  Created by Christopher Ladd on 3/30/15.
//  Copyright (c) 2015 Christopher Ladd. All rights reserved.
//

@import UIKit;

extern NSString * const CGLMediaPickerOptionUserLastPhoto;
extern NSString * const CGLMediaPickerOptionPhotoLibrary;
extern NSString * const CGLMediaPickerOptionCamera;

typedef void(^CGLMediaPickerCompletion)(UIImage *image, NSDictionary *info, NSError *error);

typedef void(^CGLMediaPickerAccessCompletion)(BOOL granted);

/**
 *  CGLMediaPicker allows the user to choose a piece of multimedia of an array of types provided by the client, and runs a completion block ones the user has either successfully chosen, or cancelled for some reason. Influenced by ClusterPrePermissions, with the goal of being lighter weight, and generally allowing clients to be more hands off.
 *
 *  It takes care of all permissions and UI, and is automatically retained in memory for as long as the user is actively choosing. There is no need for clients to maintain a reference.
 *
 *  It takes care of informing the user why permissions are lacking, when they're lacking, and sends them to Settings.app to take care of any problems they might need to.
 *
 *  In short, CGLMediaPicker lets you, the client, say: I would like the user to give me a piece of media. And then lets you sit back and wait for that media.
 */
@interface CGLMediaPicker : NSObject

/**
 *  Initializes a media picker object, with a view controller from which to present the user's chosen action.
 *
 *  @param presentingViewController a presenting view controller
 *
 *  @return a CGLMediaPicker object
 */
- (instancetype)initWithViewController:(UIViewController *)presentingViewController;

#pragma mark - Configuration

/**
 *  The array of inputs that should be presented to the user.
 *
 *  If more than one is present, the picker will present the user with an action sheet to choose between them.
 */
@property (nonatomic, copy) NSArray *inputs;

/**
 *  A friendly message presented to the user to ask permission.
 */
@property (nonatomic, copy) NSString *permissionMessage;

/**
 *  A completion block to be run once the user has either chosen, cancelled, or been unable to choose.
 */
@property (nonatomic, copy) CGLMediaPickerCompletion completion;

/**
 *  Set to YES to return a copy of the chosen image, normalized for orientation.
 */
@property (nonatomic) BOOL normalizeImage;

#pragma mark - Picking


/**
 *  Instructs the picker to begin picking. You do not need to retain a reference to this object -- it will be retained internally until the user has chosen an image, or cancelled.
 */
- (void)pick;


#pragma mark - Checking Availability

/**
 *  Asks only for access. @note that this will not actually pick for you, but will instead pre-request permissions.
 *
 *  @param completion a completion
 */
- (void)requestAccess:(CGLMediaPickerAccessCompletion)completion;

/**
 *  Whether or not a given type of input is available.
 *
 *  @param input an input type - see the CGLMediaPickerOption externs at the top of CGLMediaPicker.h
 *
 *  @return YES if available, NO otherwise
 */
+ (BOOL)sourceAvailableForInput:(NSString *)input;

/**
 *  Whether or not the user has previously authorized a given action
 *
 *  @param action an input type  - see the CGLMediaPickerOption externs at the top of CGLMediaPicker.h
 *
 *  @return YES if authorized, NO otherwise
 */
+ (BOOL)isAuthorizedForAccessForAction:(NSString *)action;


#pragma mark - Lower Level Methods

/**
 *  A convenience method to get the user's last photo.
 *
 *  @param resultHandler a result handler
 */
- (void)getLastUserPhoto:(void(^)(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info))resultHandler;

@end
