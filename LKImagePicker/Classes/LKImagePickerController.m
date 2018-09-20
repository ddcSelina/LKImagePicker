//
//  LKImagePickerControllerViewController.m
//  LKImagePicker
//
//  Created by Elliekuri on 2018/6/11.
//  Copyright © 2018年 S.U.N. All rights reserved.
//

@import AssetsLibrary;
#import "LKImagePickerController.h"
#import "LKAssetsViewController.h"
#import "LKAlbumsViewController.h"
#import "LKCameraViewController.h"
#import "LKAccessDeniedPlaceholderView.h"
#import "LKAssetsManager.h"
#import "NSBundle+LKImagePickerController.h"

@interface LKImagePickerController () <LKAssetsViewControllerDelegate, LKAlbumsViewControllerDelegate, LKCameraViewControllerDelegate>
@property (nonatomic) NSMutableOrderedSet *mutableSelectedAssetURLs;
@property (nonatomic) LKAssetsManager *assetsManager;
@property (nonatomic) UINavigationController *childNavigationController;
@property (nonatomic) UIView *accessDeniedPlaceholderView;
@property (nonatomic, weak) LKAssetsViewController *assetsViewController;
@property (nonatomic, weak) LKAlbumsViewController *albumsViewController;
@end

@implementation LKImagePickerController

#pragma mark - Accessors

- (void)setMinimumNumberOfSelection:(NSUInteger)minimumNumberOfSelection {
    _minimumNumberOfSelection = MAX(minimumNumberOfSelection, 1);
}


- (NSArray *)selectedAssetURLs {
    return [self.mutableSelectedAssetURLs array];
}


- (LKAssetsManager *)assetsManager {
    if (!_assetsManager) {
        _assetsManager = [[LKAssetsManager alloc] initWithAssetsLibrary:[[ALAssetsLibrary alloc] init]
                                                               mediaTyle:self.mediaType
                                                              groupTypes:(ALAssetsGroupSavedPhotos | ALAssetsGroupPhotoStream | ALAssetsGroupAlbum)];
        _assetsManager.excludesEmptyGroups = self.excludesEmptyAlbums;
    }
    return _assetsManager;
}


- (UIView *)accessDeniedPlaceholderView {
    if (!_accessDeniedPlaceholderView) {
        _accessDeniedPlaceholderView = [[LKAccessDeniedPlaceholderView alloc] init];
        _accessDeniedPlaceholderView.translatesAutoresizingMaskIntoConstraints = NO;
    }
    return _accessDeniedPlaceholderView;
}


#pragma mark - NSObject

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (instancetype)init {
    if ((self = [super init])) {
        _mutableSelectedAssetURLs = [NSMutableOrderedSet orderedSet];
        _mediaType = LKImagePickerControllerMediaTypeImage;
        _sourceType = LKImagePickerControllerSourceTypeLibrary;
        _allowsMultipleSelection = YES;
        _excludesEmptyAlbums = NO;
        _showsCameraCell = NO;
        _savesToPhotoLibrary = NO;
        _needsConfirmation = NO;
        _reversesAssets = NO;
        _maxScaledDimension = 0;
        _usesScaledImage = NO;
        _showsNumberOfSelectedAssets = YES;
        _numberOfColumnsInPortrait = 4;
        _numberOfColumnsInLandscape = 7;
        _minimumNumberOfSelection = 1;
        _maximumNumberOfSelection = 0;
    }
    return self;
}


#pragma mark - UIViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Check authorization status
    if ((self.sourceType == LKImagePickerControllerSourceTypeSavedPhotosAlbum || self.sourceType == LKImagePickerControllerSourceTypeLibrary) && [LKAssetsManager isAccessDenied]) {
        [self showAccessDeniedView];
        return;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(assetsAccessDenied:) name:kLKImagePickerAccessDeniedNotificationName object:nil];
    
    // Setup view controllers
    UIViewController *viewController;
    switch (self.sourceType) {
        case LKImagePickerControllerSourceTypeSavedPhotosAlbum: {
            self.childNavigationController = [[UINavigationController alloc] init];
            LKAlbumsViewController *albumsViewController = [self createAlbumsViewController];
            LKAssetsViewController *assetsViewController = [self createAssetsViewController];
            self.albumsViewController = albumsViewController;
            self.assetsViewController = assetsViewController;
            [self.childNavigationController setViewControllers:@[albumsViewController, assetsViewController]];
            viewController = self.childNavigationController;
            
            [self.assetsManager fetchAssetsGroupsWithCompletion:^(NSArray *assetsGroups) {
                if (assetsGroups.count > 0) {
                    assetsViewController.assetsGroup = [assetsGroups firstObject];
                }
            } failureBlock:nil];
            
            break;
        }
        case LKImagePickerControllerSourceTypeLibrary: {
            LKAlbumsViewController *albumsViewController = [self createAlbumsViewController];
            self.albumsViewController = albumsViewController;
            self.childNavigationController = [[UINavigationController alloc] initWithRootViewController:albumsViewController];
            viewController = self.childNavigationController;
            break;
        }
        case LKImagePickerControllerSourceTypeCamera: {
            viewController = [self createCameraViewController];
            break;
        }
    }
    
    if (viewController) {
        [self fastttAddChildViewController:viewController];
    }
}


- (BOOL)prefersStatusBarHidden {
    if (self.sourceType == LKImagePickerControllerSourceTypeCamera) {
        return YES;
    }
    
    return [self.childNavigationController.topViewController prefersStatusBarHidden];
}


#pragma mark - LKAlbumsViewControllerDelegate

- (void)albumsViewController:(LKAlbumsViewController *)viewController didSelectAssetsGroup:(ALAssetsGroup *)assetsGroup {
    LKAssetsViewController *assetsViewController = [self createAssetsViewController];
    assetsViewController.assetsGroup = assetsGroup;
    self.assetsViewController = assetsViewController;
    [self.childNavigationController pushViewController:assetsViewController animated:YES];
}


- (void)albumsViewControllerDidCancel:(LKAlbumsViewController *)viewController {
    [self cancelPicking];
}


- (void)albumsViewControllerDidFinishPicking:(LKAlbumsViewController *)viewController {
    [self finishPickingAssets];
}


- (BOOL)albumsViewControllerShouldEnableDoneButton:(LKAlbumsViewController *)viewController {
    if ([self.delegate respondsToSelector:@selector(lk_imagePickerControllerShouldEnableDoneButton:)]) {
        return [self.delegate lk_imagePickerControllerShouldEnableDoneButton:self];
    }
    
    return [self isTotalNumberOfSelectedAssetsValid];
}


- (BOOL)albumsViewControllerShouldShowSelectionInfo:(LKAlbumsViewController *)viewController {
    if (!self.showsNumberOfSelectedAssets) {
        return NO;
    }
    
    return self.mutableSelectedAssetURLs.count > 0;
}


- (NSString *)albumsViewControllerSelectionInfo:(LKAlbumsViewController *)viewController {
    return [self selectionInfoWithNumberOfSelection:self.mutableSelectedAssetURLs.count];
}


#pragma mark - LKAssetsViewControllerDelegate

- (BOOL)assetsViewController:(LKAssetsViewController *)assetsViewController shouldSelectAsset:(ALAsset *)asset {
    if ([self.delegate respondsToSelector:@selector(lk_imagePickerController:shouldSelectAsset:)]) {
        return [self.delegate lk_imagePickerController:self shouldSelectAsset:asset];
    }
    
    return !(self.minimumNumberOfSelection <= self.maximumNumberOfSelection && self.selectedAssetURLs.count >= self.maximumNumberOfSelection);
}


- (void)assetsViewController:(LKAssetsViewController *)assetsViewController didSelectAsset:(ALAsset *)asset {
    NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
    [self.mutableSelectedAssetURLs addObject:assetURL];
    
    if (!self.allowsMultipleSelection) {
        [self finishPickingAssets];
    }
}


- (void)assetsViewController:(LKAssetsViewController *)assetsViewController didDeselectAsset:(ALAsset *)asset {
    NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
    [self.mutableSelectedAssetURLs removeObject:assetURL];
}


- (BOOL)assetsViewController:(LKAssetsViewController *)assetsViewController isAssetSelected:(ALAsset *)asset {
    NSURL *assetURL = [asset valueForProperty:ALAssetPropertyAssetURL];
    return [self.selectedAssetURLs containsObject:assetURL];
}


- (void)assetsViewControllerDidFinishPicking:(LKAssetsViewController *)assetsViewController {
    [self finishPickingAssets];
}


- (void)assetsViewControllerDidSelectCamera:(LKAssetsViewController *)assetsViewController {
    self.savesToPhotoLibrary = YES;
    LKCameraViewController *cameraViewController = [self createCameraViewController];
    [self.childNavigationController pushViewController:cameraViewController animated:YES];
}


- (BOOL)assetsViewControllerShouldEnableDoneButton:(LKAssetsViewController *)assetsViewController {
    if ([self.delegate respondsToSelector:@selector(lk_imagePickerControllerShouldEnableDoneButton:)]) {
        return [self.delegate lk_imagePickerControllerShouldEnableDoneButton:self];
    }
    
    return [self isTotalNumberOfSelectedAssetsValid];
}


- (BOOL)assetsViewControllerShouldShowSelectionInfo:(LKAssetsViewController *)assetsViewController {
    if (!self.showsNumberOfSelectedAssets) {
        return NO;
    }
    
    return self.mutableSelectedAssetURLs.count > 0;
}


- (NSString *)assetsViewControllerSelectionInfo:(LKAssetsViewController *)assetsViewController {
    return [self selectionInfoWithNumberOfSelection:self.mutableSelectedAssetURLs.count];
}


#pragma mark - LKCameraViewControllerDelegate

- (void)userDeniedCameraPermissionsForCameraViewController:(LKCameraViewController *)cameraViewController {
    if ([self.delegate respondsToSelector:@selector(lk_imagePickerControllerAccessDenied:)]) {
        [self.delegate lk_imagePickerControllerAccessDenied:self];
    }
}


- (void)cameraViewControllerDidCancel:(LKCameraViewController *)cameraViewController {
    if (self.sourceType == LKImagePickerControllerSourceTypeCamera) {
        [self cancelPicking];
    } else {
        [self.childNavigationController popViewControllerAnimated:YES];
        
        // Save photos to albums if needed
        NSArray *images = cameraViewController.capturedImages;
        if (images.count == 0) {
            return;
        }
        
        if (self.savesToPhotoLibrary) {
            if ([self.delegate respondsToSelector:@selector(lk_imagePickerController:willSaveImages:)]) {
                [self.delegate lk_imagePickerController:self willSaveImages:images];
            }
            
            self.assetsViewController.ignoreChange = YES;
            
            [self.assetsManager writeImagesToSavedPhotosAlbum:images progress:^(NSURL *assetURL, NSUInteger currentCount, NSUInteger totalCount) {
                if ([self.delegate respondsToSelector:@selector(lk_imagePickerController:saveImages:withProgress:totalCount:)]) {
                    [self.delegate lk_imagePickerController:self saveImages:images withProgress:currentCount totalCount:totalCount];
                }
            } completion:^(NSArray *assetURLs, NSError *error) {
                if ([self.delegate respondsToSelector:@selector(lk_imagePickerController:didFinishSavingImages:resultAssetURLs:)]) {
                    [self.delegate lk_imagePickerController:self didFinishSavingImages:images resultAssetURLs:assetURLs];
                }
                
                [self.assetsViewController updateAssets];
                self.assetsViewController.ignoreChange = NO;
                
                [self.mutableSelectedAssetURLs addObjectsFromArray:assetURLs];
            }];
        }
    }
}


- (void)cameraViewController:(LKCameraViewController *)cameraViewController didFinishCapturingImages:(NSArray *)images {
    if (self.savesToPhotoLibrary) {
        if (images.count == 0) {
            [self finishPickingAssets];
            return;
        }
        
        // Start saving
        if ([self.delegate respondsToSelector:@selector(lk_imagePickerController:willSaveImages:)]) {
            [self.delegate lk_imagePickerController:self willSaveImages:images];
        }
        self.assetsViewController.ignoreChange = YES;
        
        [self.assetsManager writeImagesToSavedPhotosAlbum:images progress:^(NSURL *assetURL, NSUInteger currentCount, NSUInteger totalCount) {
            if ([self.delegate respondsToSelector:@selector(lk_imagePickerController:saveImages:withProgress:totalCount:)]) {
                [self.delegate lk_imagePickerController:self saveImages:images withProgress:currentCount totalCount:totalCount];
            }
        } completion:^(NSArray *assetURLs, NSError *error) {
            if ([self.delegate respondsToSelector:@selector(lk_imagePickerController:didFinishSavingImages:resultAssetURLs:)]) {
                [self.delegate lk_imagePickerController:self didFinishSavingImages:images resultAssetURLs:assetURLs];
            }
            [self.mutableSelectedAssetURLs addObjectsFromArray:assetURLs];
            [self finishPickingAssets];
        }];
    } else {
        if ([self.delegate respondsToSelector:@selector(lk_imagePickerController:didFinishPickingImages:)]) {
            [self.delegate lk_imagePickerController:self didFinishPickingImages:images];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }
}


- (BOOL)cameraViewControllerShouldTakePicture:(LKCameraViewController *)cameraViewController {
    if ([self.delegate respondsToSelector:@selector(lk_imagePickerController:shouldTakePictureWithCapturedImages:)]) {
        return [self.delegate lk_imagePickerController:self shouldTakePictureWithCapturedImages:cameraViewController.capturedImages];
    }
    
    NSUInteger numberOfCapturedImages = cameraViewController.capturedImages.count;
    BOOL result = self.minimumNumberOfSelection > self.maximumNumberOfSelection;
    
    return result || (self.selectedAssetURLs.count + numberOfCapturedImages) < self.maximumNumberOfSelection;
}


- (BOOL)cameraViewControllerShouldEnableDoneButton:(LKCameraViewController *)cameraViewController {
    if ([self.delegate respondsToSelector:@selector(lk_imagePickerControllerShouldEnableDoneButton:)]) {
        return [self.delegate lk_imagePickerControllerShouldEnableDoneButton:self];
    }
    
    NSUInteger numberOfCapturedImages = cameraViewController.capturedImages.count;
    NSUInteger numberOfSelection = self.selectedAssetURLs.count;
    
    return [self isNumberOfSelectionValid:(numberOfSelection + numberOfCapturedImages)];
}


- (BOOL)cameraViewControllerShouldShowSelectionInfo:(LKCameraViewController *)cameraViewController {
    if (!self.showsNumberOfSelectedAssets) {
        return NO;
    }
    
    NSUInteger numberOfCapturedImages = cameraViewController.capturedImages.count;
    NSUInteger numberOfSelection = self.selectedAssetURLs.count;
    return (numberOfCapturedImages + numberOfSelection) > 0;
}


- (NSString *)cameraViewControllerSelectionInfo:(LKCameraViewController *)cameraViewController {
    return [self selectionInfoWithNumberOfSelection:(cameraViewController.capturedImages.count + self.mutableSelectedAssetURLs.count)];
}


#pragma mark - Private

- (void)assetsAccessDenied:(NSNotification *)notification {
    if ([self.delegate respondsToSelector:@selector(lk_imagePickerControllerAccessDenied:)]) {
        [self.delegate lk_imagePickerControllerAccessDenied:self];
    }
    
    [self showAccessDeniedView];
}


- (void)showAccessDeniedView {
    if (self.accessDeniedPlaceholderView.superview) {
        return;
    }
    
    UIViewController *viewController = [[UIViewController alloc] init];
    viewController.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:LKImagePickerLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelPicking)];
    
    UIView *view = viewController.view;
    [view addSubview:self.accessDeniedPlaceholderView];
    
    // Add constraints
    [view addConstraint:[NSLayoutConstraint constraintWithItem:self.accessDeniedPlaceholderView attribute:NSLayoutAttributeLeft relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeLeft multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:self.accessDeniedPlaceholderView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeTop multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:self.accessDeniedPlaceholderView attribute:NSLayoutAttributeRight relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeRight multiplier:1 constant:0]];
    [view addConstraint:[NSLayoutConstraint constraintWithItem:self.accessDeniedPlaceholderView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:view attribute:NSLayoutAttributeBottom multiplier:1 constant:0]];
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:viewController];
    [self fastttAddChildViewController:navigationController];
}


- (LKAlbumsViewController *)createAlbumsViewController {
    LKAlbumsViewController *albumsViewController = [[LKAlbumsViewController alloc] init];
    albumsViewController.delegate = self;
    albumsViewController.assetsManager = self.assetsManager;
    albumsViewController.allowsMultipleSelection = self.allowsMultipleSelection;
    return albumsViewController;
}


- (LKAssetsViewController *)createAssetsViewController {
    LKAssetsViewController *assetsViewController = [[LKAssetsViewController alloc] init];
    assetsViewController.delegate = self;
    assetsViewController.allowsMultipleSelection = self.allowsMultipleSelection;
    assetsViewController.reversesAssets = self.reversesAssets;
    assetsViewController.showsCameraCell = self.showsCameraCell;
    assetsViewController.minimumInteritemSpacing = 2.0;
    assetsViewController.minimumLineSpacing = 4.0;
    assetsViewController.numberOfColumnsInPortrait = self.numberOfColumnsInPortrait;
    assetsViewController.numberOfColumnsInLandscape = self.numberOfColumnsInLandscape;
    return assetsViewController;
}


- (LKCameraViewController *)createCameraViewController {
    LKCameraViewController *cameraViewController = [[LKCameraViewController alloc] init];
    cameraViewController.delegate = self;
    cameraViewController.allowsMultipleSelection = self.allowsMultipleSelection;
    cameraViewController.needsConfirmation = self.needsConfirmation;
    cameraViewController.usesScaledImage = self.usesScaledImage;
    cameraViewController.maxScaledDimension = self.maxScaledDimension;
    return cameraViewController;
}


- (NSString *)selectionInfoWithNumberOfSelection:(NSInteger)count {
    NSString *text = nil;
    if (self.maximumNumberOfSelection > 0) {
        text = [NSString stringWithFormat:LKImagePickerLocalizedString(@"Selected: %@/%@", nil), @(count), @(self.maximumNumberOfSelection)];
    } else {
        text = [NSString stringWithFormat:LKImagePickerLocalizedString(@"Selected: %@", nil), @(count)];
    }
    return text;
}


- (BOOL)isNumberOfSelectionValid:(NSUInteger)numberOfSelection {
    BOOL result = (numberOfSelection >= self.minimumNumberOfSelection);
    
    if (self.minimumNumberOfSelection <= self.maximumNumberOfSelection) {
        result = result && numberOfSelection <= self.maximumNumberOfSelection;
    }
    
    return result;
}


- (BOOL)isTotalNumberOfSelectedAssetsValid {
    NSUInteger numberOfSelection = self.selectedAssetURLs.count;
    return [self isNumberOfSelectionValid:numberOfSelection];
}


- (void)cancelPicking {
    if ([self.delegate respondsToSelector:@selector(lk_imagePickerControllerDidCancel:)]) {
        [self.delegate lk_imagePickerControllerDidCancel:self];
    } else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}


- (void)finishPickingAssets {
    [self.assetsManager fetchAssetsWithAssetURLs:self.selectedAssetURLs progress:nil completion:^(NSArray *assets, NSError *error) {
        if ([self.delegate respondsToSelector:@selector(lk_imagePickerController:didFinishPickingAssets:)]) {
            [self.delegate lk_imagePickerController:self didFinishPickingAssets:assets];
        } else {
            [self dismissViewControllerAnimated:YES completion:nil];
        }
    }];
}

@end
