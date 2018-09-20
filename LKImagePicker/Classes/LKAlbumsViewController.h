//
//  LKAlbumsViewController.h
//  LKImagePicker
//
//  Created by Elliekuri on 2018/6/11.
//  Copyright © 2018年 S.U.N. All rights reserved.
//

@import UIKit;

@class LKAssetsManager;
@protocol LKAlbumsViewControllerDelegate;

@interface LKAlbumsViewController : UITableViewController

@property (nonatomic) LKAssetsManager *assetsManager;
@property (nonatomic, readonly) NSArray *assetsGroups;
@property (nonatomic, weak) id<LKAlbumsViewControllerDelegate> delegate;
@property (nonatomic) BOOL allowsMultipleSelection;

@end


@class ALAssetsGroup;

@protocol LKAlbumsViewControllerDelegate <NSObject>

@optional
- (void)albumsViewControllerDidCancel:(LKAlbumsViewController *)viewController;
- (void)albumsViewControllerDidFinishPicking:(LKAlbumsViewController *)viewController;
- (void)albumsViewController:(LKAlbumsViewController *)viewController didSelectAssetsGroup:(ALAssetsGroup *)assetsGroup;
- (BOOL)albumsViewControllerShouldEnableDoneButton:(LKAlbumsViewController *)viewController;
- (BOOL)albumsViewControllerShouldShowSelectionInfo:(LKAlbumsViewController *)viewController;
- (NSString *)albumsViewControllerSelectionInfo:(LKAlbumsViewController *)viewController;

@end
