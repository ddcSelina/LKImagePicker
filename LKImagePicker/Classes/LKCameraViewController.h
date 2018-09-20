//
//  LKCameraViewController.h
//  LKImagePicker
//
//  Created by Elliekuri on 2018/6/11.
//  Copyright © 2018年 S.U.N. All rights reserved.
//

@import UIKit;

@protocol LKCameraViewControllerDelegate;

@interface LKCameraViewController : UIViewController

@property (nonatomic, weak) id<LKCameraViewControllerDelegate> delegate;
//@property (nonatomic, readonly) FastttCamera *fastCamera;
@property (nonatomic, readonly) NSArray *capturedImages;
@property (nonatomic) CGSize thumbnailSize;
@property (nonatomic) BOOL allowsMultipleSelection;
@property (nonatomic) BOOL needsConfirmation;
@property (nonatomic) BOOL usesScaledImage;
@property (nonatomic) CGFloat maxScaledDimension;

@end

@protocol LKCameraViewControllerDelegate <NSObject>
@optional
- (void)cameraViewControllerDidCancel:(LKCameraViewController *)cameraViewController;
- (void)cameraViewController:(LKCameraViewController *)cameraViewController didFinishCapturingImages:(NSArray *)images;
- (BOOL)cameraViewControllerShouldTakePicture:(LKCameraViewController *)cameraViewController;

- (BOOL)cameraViewControllerShouldEnableDoneButton:(LKCameraViewController *)cameraViewController;
- (void)userDeniedCameraPermissionsForCameraViewController:(LKCameraViewController *)cameraViewController;

- (BOOL)cameraViewControllerShouldShowSelectionInfo:(LKCameraViewController *)cameraViewController;
- (NSString *)cameraViewControllerSelectionInfo:(LKCameraViewController *)cameraViewController;

@end
