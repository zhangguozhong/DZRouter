//
//  DZRouter.h
//  DZRouter
//
//  Created by 张国忠 on 2018/3/20.
//  Copyright © 2018年 张国忠. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "UIViewController+DZRouter.h"
#import <NSObject+ZTopViewController.h>

@interface DZRouter : NSObject

+ (instancetype)sharedDZRouter;


/**
 设置可识别的scheme，为了过滤非法的路由；

 @param schemes 可识别的schemes
 */
- (void)configAllowSchemes:(NSArray *)schemes;


/**
 注册所有路由
 */
+ (void)registerRoutePatterns;


/**
 注册路由
 
 @param routePattern 路由规则
 @param targetControllerName 目标控制器名称
 */
+ (void)registerRoutePattern:(NSString *)routePattern targetControllerName:(NSString *)targetControllerName;


/**
 注册路由
 
 @param routePattern 路由规则
 @param targetControllerName 目标控制器名称
 @param handlerBlock 回调block [handlerTag:回调标记, parameters:回调数据]
 */
+ (void)registerRoutePattern:(NSString *)routePattern targetControllerName:(NSString *)targetControllerName handler:(void(^)(NSString *handlerTag, id parameters))handlerBlock;


/**
 注销路由
 
 @param routePattern 路由规则
 */
+ (void)deregisterRoutePattern:(NSString *)routePattern;


/**
 注销路由
 
 @param className Class名称
 */
+ (void)deregisterRoutePatternWithController:(Class)className;


/**
 开始路由
 
 @param routePattern 路由规则
 @return 是否可以路由
 */
+ (BOOL)startRoute:(NSString *)routePattern;


/**
 开始路由
 
 @param routePattern 路由规则
 @param completion 可以执行的回调事件
 @return 是否可以执行路由
 */
+ (BOOL)startRoute:(NSString *)routePattern completion:(void(^)(UIViewController *targetController))completion;


/**
 开始路由
 
 @param URL 路由URL
 @return 是否可以路由
 */
+ (BOOL)startRouteWithURL:(NSURL *)URL;


/**
 开始路由
 
 @param URL 路由URL
 @param completion 可以执行的回调事件
 @return 是否可以路由
 */
+ (BOOL)startRouteWithURL:(NSURL *)URL completion:(void(^)(UIViewController *targetController))completion;

@end
