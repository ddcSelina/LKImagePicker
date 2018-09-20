//
//  LKAppDelegate.m
//  LKImagePicker
//
//  Created by Elliekuri on 2018/6/6.
//  Copyright © 2018年 S.U.N. All rights reserved.
//

#import "LKAppDelegate.h"
#import "LKViewController.h"

@interface LKAppDelegate ()

@end

@implementation LKAppDelegate

#pragma mark - Accessors

@synthesize window = _window;

- (UIWindow *)window {
    if (!_window) {
        _window = [[UIWindow alloc] init];
        _window.frame = [[UIScreen mainScreen] bounds];
        _window.backgroundColor = [UIColor whiteColor];
    }
    return _window;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:[[LKViewController alloc] init]];
    self.window.rootViewController = navigationController;
    [self.window makeKeyAndVisible];
    return YES;
}

@end
