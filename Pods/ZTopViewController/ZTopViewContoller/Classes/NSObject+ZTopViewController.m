//
//  NSObject+ZTopViewController.m
//  ZTopViewContoller
//
//  Created by 张国忠 on 2018/3/20.
//  Copyright © 2018年 张国忠. All rights reserved.
//

#import "NSObject+ZTopViewController.h"

@implementation NSObject (ZTopViewController)

- (UIViewController*)currentController {
    UIViewController *currentController = [self getCurrentVCFromRootVC:[UIApplication sharedApplication].keyWindow.rootViewController];
    //    while (currentController.presentedViewController) {
    //        // 视图是被presented出来的
    //        currentController=[self getCurrentVCFromRootVC:currentController.presentedViewController];
    //    }
    return currentController;
}

- (UIViewController*)getCurrentVCFromRootVC:(UIViewController*)rootController {
    UIViewController *currentController;
    if (rootController.presentedViewController) {
        // 视图是被presented出来的（但如果presented出来多个视图并不是UITabBarController或者UINavigationController，rootVC.presentedViewController获取到的视图就有可能不是最顶部的视图，因此需要再次递归）
        // rootVC=rootVC.presentedViewController; (有可能获取不到最顶部视图)
        rootController=[self getCurrentVCFromRootVC:rootController.presentedViewController];
    }
    if ([rootController isKindOfClass:[UINavigationController class]]) {
        // 视图为UITabBarController
        currentController = [self getCurrentVCFromRootVC:[(UINavigationController*)rootController topViewController]];
    }else if ([rootController isKindOfClass:[UITabBarController class]]) {
        // 视图为UINavigationController
        currentController=[self getCurrentVCFromRootVC:[(UITabBarController*)rootController selectedViewController]];
    } else{
        currentController=rootController;
    }
    return currentController;
}

@end
