//
//  CGLMediaPicker.m
//
//  Created by Christopher Ladd on 3/30/15.
//  Copyright (c) 2015 Christopher Ladd. All rights reserved.
//

#import "CGLMediaPicker.h"
@import AssetsLibrary;
@import Photos;

NSString * const CGLMediaPickerOptionUserLastPhoto = @"Use Last Photo";
NSString * const CGLMediaPickerOptionPhotoLibrary = @"Photo Library";
NSString * const CGLMediaPickerOptionCamera = @"Camera";

NSInteger const CGLMediaPickerTagPrePermissionsPhotos = 1000;
NSInteger const CGLMediaPickerTagPrePermissionsCamera = 1001;
NSInteger const CGLMediaPickerTagPermissionDenied = 1002;

@interface CGLMediaPicker () <UIAlertViewDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate>
@property (nonatomic) NSString *identifier;
@property (nonatomic) UIViewController *presentingViewController;
@property (nonatomic) NSString *selectedInput;

@end

@implementation CGLMediaPicker

+ (NSMutableDictionary *)keyedPickers {
    static NSMutableDictionary *pickers;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        pickers = [NSMutableDictionary dictionary];
    });
    
    return pickers;
}

+ (void)removePicker:(CGLMediaPicker *)picker {
    [[self keyedPickers] removeObjectForKey:picker.identifier];
}

- (instancetype)initWithViewController:(UIViewController *)presentingViewController {
    self = [super init];
    
    if (self) {
        _presentingViewController = presentingViewController;
    }
    
    return self;
}

- (NSString *)identifier {
    if (!_identifier) {
        _identifier = [[NSUUID UUID] UUIDString];
    }
    
    return _identifier;
}

- (void)pick {
    NSAssert([self.inputs count] > 0, @"You must specify at least one  input");
    NSAssert(self.completion, @"You must specify a completion");
    
    [[self class] keyedPickers][self.identifier] = self;
    
    if ([self.inputs count] == 1) {
        // then just do that action
        self.selectedInput = [[self inputs] firstObject];
        [self checkPermissions];
    }
    else {
        [self presentInputOptions];
    }
}

- (void)presentInputOptions {
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:NSLocalizedString(@"Cancel", nil) destructiveButtonTitle:nil otherButtonTitles:nil];
    
    for (NSString *option in self.inputs) {
        if ([[self class] sourceAvailableForInput:option]) {
            [actionSheet addButtonWithTitle:option];
        }
    }
    
    [actionSheet showInView:self.presentingViewController.view];
}

+ (UIImagePickerControllerSourceType)sourceTypeForInput:(NSString *)input {
    if ([input isEqualToString:CGLMediaPickerOptionCamera]) {
        return UIImagePickerControllerSourceTypeCamera;
    }
    
    return UIImagePickerControllerSourceTypePhotoLibrary;
}

+ (BOOL)sourceAvailableForInput:(NSString *)input {
    return [UIImagePickerController isSourceTypeAvailable:[self sourceTypeForInput:input]];
}

- (void)presentImagePickerForInput:(NSString *)input {
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.sourceType = [[self class] sourceTypeForInput:input];
    
    if (imagePicker.sourceType == UIImagePickerControllerSourceTypeCamera) {
        imagePicker.allowsEditing = YES;
    }
    
    imagePicker.delegate = self;
    
    [self.presentingViewController presentViewController:imagePicker animated:YES completion:nil];
}

- (void)failWithReason:(NSString *)reason {
    if (!reason) {
        reason = @"Undefined Error";
    }
    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:404 userInfo:@{NSLocalizedDescriptionKey : reason}];
    
    if (self.completion) {
        self.completion(nil, nil, error);
    }
    
    [[self class] removePicker:self];
}

- (void)getLastUserPhoto:(void(^)(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info))resultHandler {
    PHImageManager *imageManager = [PHImageManager defaultManager];
    PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
    requestOptions.synchronous = YES;
    
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    fetchOptions.sortDescriptors = @[[[NSSortDescriptor alloc] initWithKey:@"creationDate" ascending:NO]];
    
    PHFetchResult *result = [PHAsset fetchAssetsWithMediaType:PHAssetMediaTypeImage options:fetchOptions];
    
    if (result.count > 0) {
        [imageManager requestImageDataForAsset:[result firstObject] options:requestOptions resultHandler:resultHandler];
    }
    else {
        [self failWithReason:@"No last photo exists"];
    }
    
}

- (void)getAssetsForInput:(NSString *)input {
    if ([input isEqualToString:CGLMediaPickerOptionCamera] ||
        [input isEqualToString:CGLMediaPickerOptionPhotoLibrary]) {
        [self presentImagePickerForInput:input];
    }
    else if ([input isEqualToString:CGLMediaPickerOptionUserLastPhoto]) {
        [self getLastUserPhoto:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            if (imageData) {
                UIImage *image = [UIImage imageWithData:imageData];
                if (self.completion) {
                    self.completion(image, info, nil);
                }
            }
            else {
                [self failWithReason:@"No image data"];
            }
        }];
    }
}

- (void)checkPermissions {
    if ([self.selectedInput isEqualToString:CGLMediaPickerOptionCamera]) {
        [self checkCameraPermissions];
    }
    else {
        [self checkPhotoPermissions];
    }
}

+ (BOOL)isAuthorizedForAccessForAction:(NSString *)action {
    if ([action isEqualToString:CGLMediaPickerOptionUserLastPhoto]) {
        AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
        return authStatus == AVAuthorizationStatusAuthorized;
    }

    return NO;
}

- (void)checkCameraPermissions {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusAuthorized) {
        [self getAssetsForInput:self.selectedInput];
    }
    else if (authStatus == AVAuthorizationStatusDenied) {
        [self presentPermissionDeniedAlert:NSLocalizedString(@"Camera Unavailable", nil)];
    }
    else if (authStatus == AVAuthorizationStatusRestricted) {
        [self failWithRestrictedAlert:@"Camera Unavailable" message:@"Camera is unavailable on this device."];
    }
    else if (authStatus == AVAuthorizationStatusNotDetermined) {
        [self preRequestForAssetNamed:@"Camera" message:self.permissionMessage tag:CGLMediaPickerTagPrePermissionsCamera];
    }
}

- (void)checkPhotoPermissions {
    ALAuthorizationStatus status = [ALAssetsLibrary authorizationStatus];
    if (status == ALAuthorizationStatusAuthorized) {
        [self getAssetsForInput:self.selectedInput];
    }
    else if (status == ALAuthorizationStatusDenied) {
        [self presentPermissionDeniedAlert:NSLocalizedString(@"Photos Unavailable", nil)];
    }
    else if (status == ALAuthorizationStatusRestricted) {
        [self failWithRestrictedAlert:@"Photos Unavailable" message:@"Photos are unavailable on this device."];
    }
    else if (status == ALAuthorizationStatusNotDetermined) {
        [self preRequestForAssetNamed:@"Photos" message:self.permissionMessage tag:CGLMediaPickerTagPrePermissionsPhotos];
    }
}

// kudos to https://github.com/clusterinc/ClusterPrePermissions
- (void)preRequestForAssetNamed:(NSString *)assetName message:(NSString *)message tag:(NSInteger)tag {
    NSString *appName = [[NSBundle mainBundle] infoDictionary][@"CFBundleDisplayName"];

    NSString *title = [NSString stringWithFormat:@"Let %@ Access %@?", appName, assetName];
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"Not Now", nil) otherButtonTitles:NSLocalizedString(@"Grant Access", nil), nil];
    alertView.tag = tag;
    [alertView show];
}

- (void)presentCameraPermissionDeniedAlert:(NSString *)title {
    NSString *message = @"You've denied this app permission to use your camera. You can change this in settings.";
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:NSLocalizedString(@"Settings", nil), nil];
    alertView.tag = CGLMediaPickerTagPermissionDenied;
    [alertView show];
}

- (void)failWithRestrictedAlert:(NSString *)title message:(NSString *)message {
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:nil];
    alertView.tag = CGLMediaPickerTagPermissionDenied;
    [alertView show];
    
    [self failWithReason:@"Restricted"];
}

- (void)presentPermissionDeniedAlert:(NSString *)title {
    NSString *message = @"You've denied this app permission to use your photos. You can change this in settings.";
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:NSLocalizedString(@"OK", nil) otherButtonTitles:NSLocalizedString(@"Settings", nil), nil];
    alertView.tag = CGLMediaPickerTagPermissionDenied;
    [alertView show];
}

- (void)requestCameraPermissions {
    [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo
                             completionHandler:^(BOOL granted) {
                                 dispatch_async(dispatch_get_main_queue(), ^{
                                     if (granted) {
                                         [self getAssetsForInput:self.selectedInput];
                                     }
                                     else {
                                         [self presentCameraPermissionDeniedAlert:@"Camera Unavailable"];
                                     }
                                 });
                             }];
}

- (void)requestPhotoPermissions {
    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
    [library enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [self getAssetsForInput:self.selectedInput];
        
        *stop = YES;
    } failureBlock:^(NSError *error) {
        [self presentPermissionDeniedAlert:NSLocalizedString(@"Photos Unavailable", nil)];
    }];
}

- (void)handlePrePermissionsAlertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        [self failWithReason:@"Permission denied"];
    }
    else if (alertView.tag == CGLMediaPickerTagPrePermissionsPhotos) {
        [self requestPhotoPermissions];
    }
    else if (alertView.tag == CGLMediaPickerTagPrePermissionsCamera) {
        [self requestCameraPermissions];
    }
}

- (void)handlePermissionDenied:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex != alertView.cancelButtonIndex) {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UIApplicationOpenSettingsURLString]];
    }
    
    [self failWithReason:@"Permission denied"];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == CGLMediaPickerTagPrePermissionsPhotos ||
        alertView.tag == CGLMediaPickerTagPrePermissionsCamera) {
        [self handlePrePermissionsAlertView:alertView clickedButtonAtIndex:buttonIndex];
    }
    else if (alertView.tag == CGLMediaPickerTagPermissionDenied) {
        [self handlePermissionDenied:alertView clickedButtonAtIndex:buttonIndex];
    }
}

- (UIImage *)normalizedImageFromImage:(UIImage *)image {
    if (image.imageOrientation == UIImageOrientationUp)
        return image;
    
    CGSize size = image.size;
    UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
    [image drawInRect:(CGRect){{0, 0}, size}];
    UIImage* normalizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return normalizedImage;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    __weak __typeof(self) weakSelf = self;
    [picker dismissViewControllerAnimated:YES completion:^{
        if (weakSelf.completion) {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                UIImage *image = info[UIImagePickerControllerOriginalImage];
                
                if (weakSelf.normalizeImage) {
                    image = [weakSelf normalizedImageFromImage:image];
                }
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    weakSelf.completion(image, info, nil);
                    [CGLMediaPicker removePicker:self];
                });
            });
        }
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:200 userInfo:@{NSLocalizedDescriptionKey : @"User Cancelled Picker"}];
    self.completion(nil, nil, error);
    [CGLMediaPicker removePicker:self];
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) {
        NSError *error = [NSError errorWithDomain:NSStringFromClass([self class]) code:200 userInfo:@{NSLocalizedDescriptionKey : @"User Cancelled"}];
        self.completion(nil, nil, error);
        [CGLMediaPicker removePicker:self];
    }
    else {
        self.selectedInput = [actionSheet buttonTitleAtIndex:buttonIndex];
        [self checkPermissions];
    }
}

@end
