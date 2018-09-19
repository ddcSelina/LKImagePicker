//
//  LKAssetsViewController.h
//  LKImagePicker
//
//  Created by Elliekuri on 2018/6/11.
//  Copyright © 2018年 S.U.N. All rights reserved.
//

@import UIKit;

@class ALAssetsGroup;
@protocol LKAssetsViewControllerDelegate;
@interface LKAssetsViewController : UICollectionViewController
@property (nonatomic) ALAssetsGroup *assetsGroup;
@property (nonatomic, readonly) NSArray *assets;
@property (nonatomic, weak) id<LKAssetsViewControllerDelegate> delegate;
@property (nonatomic) BOOL allowsMultipleSelection;
@property (nonatomic) BOOL reversesAssets;
@property (nonatomic) BOOL showsCameraCell;
@property (nonatomic) CGFloat minimumInteritemSpacing;
@property (nonatomic) CGFloat minimumLineSpacing;
@property (nonatomic) NSUInteger numberOfColumnsInPortrait;
@property (nonatomic) NSUInteger numberOfColumnsInLandscape;
@property (nonatomic) BOOL ignoreChange;

- (void)updateAssets;

@end


@class ALAsset;

@protocol LKAssetsViewControllerDelegate <NSObject>

@optional
- (BOOL)assetsViewController:(LKAssetsViewController *)assetsViewController shouldSelectAsset:(ALAsset *)asset;
- (void)assetsViewController:(LKAssetsViewController *)assetsViewController didSelectAsset:(ALAsset *)asset;
- (void)assetsViewController:(LKAssetsViewController *)assetsViewController didDeselectAsset:(ALAsset *)asset;

- (void)assetsViewControllerDidFinishPicking:(LKAssetsViewController *)assetsViewController;
- (void)assetsViewControllerDidCancel:(LKAssetsViewController *)assetsViewController;

- (void)assetsViewControllerDidSelectCamera:(LKAssetsViewController *)assetsViewController;

- (BOOL)assetsViewControllerShouldEnableDoneButton:(LKAssetsViewController *)assetsViewController;
- (BOOL)assetsViewController:(LKAssetsViewController *)assetsViewController isAssetSelected:(ALAsset *)asset;
- (BOOL)assetsViewControllerShouldShowSelectionInfo:(LKAssetsViewController *)assetsViewController;
- (NSString *)assetsViewControllerSelectionInfo:(LKAssetsViewController *)assetsViewController;

@end
