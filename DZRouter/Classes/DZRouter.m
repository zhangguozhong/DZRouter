//
//  DZRouter.m
//  DZRouter
//
//  Created by 张国忠 on 2018/3/20.
//  Copyright © 2018年 张国忠. All rights reserved.
//

#import "DZRouter.h"

@interface DZRouter ()

/**
 保存所有路由
 */
@property(nonatomic,strong) NSMutableDictionary *routesDictionary;

/**
 保存可识别的schemes
 */
@property(nonatomic,strong) NSMutableArray *allowSchemes;

@end

@implementation DZRouter

#pragma mark - class method

+ (instancetype)sharedDZRouter {
    static DZRouter *sharedDZRouterObj = nil;
    static dispatch_once_t onceRouterToken;
    
    dispatch_once(&onceRouterToken, ^{
        if (!sharedDZRouterObj) {
            sharedDZRouterObj = [[self alloc] init];
        }
    });
    return sharedDZRouterObj;
}


+ (void)registerRoutePatterns {
    NSString *routeDataStr = [[NSBundle mainBundle] pathForResource:@"routes" ofType:@".plist"];
    NSDictionary *routes = [NSDictionary dictionaryWithContentsOfFile:routeDataStr];
    
    if (routes && routes.count > 0) {
        [routes enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull routePattern, NSString *  _Nonnull targetControllerName, BOOL * _Nonnull stop) {
            [self registerRoutePattern:routePattern targetControllerName:targetControllerName];
        }];
    }
}


+ (void)registerRoutePattern:(NSString *)routePattern targetControllerName:(NSString *)targetControllerName {
    [self registerRoutePattern:routePattern targetControllerName:targetControllerName handler:nil];
}

+ (void)registerRoutePattern:(NSString *)routePattern targetControllerName:(NSString *)targetControllerName handler:(void(^)(NSString *handlerTag, id parameters))handlerBlock {
    
    if (!routePattern.length && !targetControllerName.length) return;
    
    [[self sharedDZRouter] addRoutePattern:routePattern targetControllerName:targetControllerName handler:handlerBlock];
}

+ (void)deregisterRoutePattern:(NSString *)routePattern {
    [[self sharedDZRouter] removeRoutePattern:routePattern];
}

+ (void)deregisterRoutePatternWithController:(Class)class {
    [[self sharedDZRouter] removeRoutePatternWithController:class];
}

+ (BOOL)startRoute:(NSString *)routePattern {
    
    if (!routePattern.length) return NO;
    
    NSURL *URL = [NSURL URLWithString:[routePattern stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];
    
    return [self startRouteWithURL:URL];
}


+ (BOOL)startRouteWithURL:(NSURL *)URL {
    
    if (!URL) return NO;
    
    return [self analysisRoutePattern:URL completion:nil];
}


+ (BOOL)startRoute:(NSString *)routePattern completion:(void (^)(UIViewController *))completion {
    
    if (!routePattern.length) return NO;
    
    NSURL *URL = [NSURL URLWithString:[routePattern stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLFragmentAllowedCharacterSet]]];
    
    return [self startRouteWithURL:URL completion:completion];
}


+ (BOOL)startRouteWithURL:(NSURL *)URL completion:(void (^)(UIViewController *))completion {
    
    if (!URL) return NO;
    
    return [self analysisRoutePattern:URL completion:completion];
}


+ (BOOL)analysisRoutePattern:(NSURL *)URL completion:(void (^)(UIViewController *))completion{
    
    NSString *routePattern = [URL absoluteString];
    
    NSURLComponents *components = [NSURLComponents componentsWithString:routePattern];
    
    NSString *scheme = components.scheme;
    
    //scheme规则自己添加
    NSAssert([[DZRouter sharedDZRouter] isVaildScheme:scheme], @"scheme规则不匹配");
    
    if (components.host.length > 0 && (![components.host isEqualToString:@"localhost"] && [components.host rangeOfString:@"."].location == NSNotFound)) {
        NSString *host = [components.percentEncodedHost copy];
        components.host = @"/";
        components.percentEncodedPath = [host stringByAppendingPathComponent:(components.percentEncodedPath ?: @"")];
    }
    
    NSString *path = [components percentEncodedPath];
    
    if (components.fragment != nil) {
        BOOL fragmentContainsQueryParams = NO;
        NSURLComponents *fragmentComponents = [NSURLComponents componentsWithString:components.percentEncodedFragment];
        
        if (fragmentComponents.query == nil && fragmentComponents.path != nil) {
            fragmentComponents.query = fragmentComponents.path;
        }
        
        if (fragmentComponents.queryItems.count > 0) {
            fragmentContainsQueryParams = fragmentComponents.queryItems.firstObject.value.length > 0;
        }
        
        if (fragmentContainsQueryParams) {
            components.queryItems = [(components.queryItems ?: @[]) arrayByAddingObjectsFromArray:fragmentComponents.queryItems];
        }
        
        if (fragmentComponents.path != nil && (!fragmentContainsQueryParams || ![fragmentComponents.path isEqualToString:fragmentComponents.query])) {
            path = [path stringByAppendingString:[NSString stringWithFormat:@"#%@", fragmentComponents.percentEncodedPath]];
        }
    }
    
    if (path.length > 0 && [path characterAtIndex:0] == '/') {
        path = [path substringFromIndex:1];
    }
    
    if (path.length > 0 && [path characterAtIndex:path.length - 1] == '/') {
        path = [path substringToIndex:path.length - 1];
    }
    
    //获取queryItem
    NSArray <NSURLQueryItem *> *queryItems = [components queryItems] ?: @[];
    NSMutableDictionary *queryParams = [NSMutableDictionary dictionary];
    for (NSURLQueryItem *item in queryItems) {
        if (item.value == nil) {
            continue;
        }
        
        if (queryParams[item.name] == nil) {
            queryParams[item.name] = item.value;
        } else if ([queryParams[item.name] isKindOfClass:[NSArray class]]) {
            NSArray *values = (NSArray *)(queryParams[item.name]);
            queryParams[item.name] = [values arrayByAddingObject:item.value];
        } else {
            id existingValue = queryParams[item.name];
            queryParams[item.name] = @[existingValue, item.value];
        }
    }
    
    NSDictionary *params = queryParams.copy;
    
    return [[self sharedDZRouter] pushTargetControllerWithRoutePattern:&routePattern queryParams:&params completion:completion];
}

#pragma mark - instance method
- (void)addRoutePattern:(NSString *)routePattern targetControllerName:(NSString *)targetControllerName handler:(void (^)(NSString *, id))handlerBlock {
    if (!routePattern.length && !targetControllerName.length) return;
    
    NSArray *pathComponents = [self pathComponentsFromRoutePattern:routePattern];
    
    if (pathComponents.count > 1) {
        //for example:demo.Amodule.product.detail
        NSString *components = [pathComponents componentsJoinedByString:@"."];
        
        NSMutableDictionary *routes = self.routesDictionary;
        
        if (![routes objectForKey:routePattern]) {
            NSMutableDictionary *controllerHandler = [NSMutableDictionary dictionary];
            if (handlerBlock) {
                [controllerHandler setValue:[handlerBlock copy] forKey:targetControllerName];
                routes[components] = controllerHandler;
            }else{
                routes[components] = targetControllerName;
            }
        }
    }
    
}

- (void)removeRoutePattern:(NSString *)routePattern {
    NSMutableArray *pathComponents = [NSMutableArray arrayWithArray:[self pathComponentsFromRoutePattern:routePattern]];
    
    if (pathComponents.count >= 1) {
        NSString *components = [pathComponents componentsJoinedByString:@"."];
        
        NSMutableDictionary *routes = self.routesDictionary;
        
        if ([routes objectForKey:components]) {
            [routes removeObjectForKey:components];
        }
    }
}

- (void)removeRoutePatternWithController:(Class)class {
    NSString *classString = NSStringFromClass(class);
    
    [self.routesDictionary enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        
        NSString *targetControllerName = nil;
        
        if ([obj isKindOfClass:[NSString class]]) {
            targetControllerName = (NSString *)obj;
        }else if ([obj isKindOfClass:[NSDictionary class]]) {
            NSDictionary *controllerHandler = (NSDictionary *)obj;
            targetControllerName = controllerHandler.allKeys.firstObject;
        }
        
        if ([targetControllerName isEqualToString:classString]) {
            [self.routesDictionary removeObjectForKey:key];
            
            *stop = YES;
        }
    }];
}

- (NSArray *)pathComponentsFromRoutePattern:(NSString*)routePattern {
    NSMutableArray *pathComponents = [NSMutableArray array];
    
    if ([routePattern rangeOfString:@"://"].location != NSNotFound) {
        
        NSArray *pathSegments = [routePattern componentsSeparatedByString:@"://"];
        
        NSAssert([self isVaildScheme:pathSegments.firstObject], @"scheme规则不匹配");
        [pathComponents addObject:pathSegments.firstObject];
        
        routePattern = pathSegments.lastObject;
        if (!routePattern.length) {
            [pathComponents addObject:@"~"];
        }
    }
    
    for (NSString *pathComponent in [[NSURL URLWithString:routePattern] pathComponents]) {
        if ([pathComponent isEqualToString:@"/"]) continue;
        if ([[pathComponent substringToIndex:1] isEqualToString:@"?"]) break;
        [pathComponents addObject:pathComponent];
    }
    
    return [pathComponents copy];
}

- (BOOL)pushTargetControllerWithRoutePattern:(NSString **)routePattern queryParams:(NSDictionary **)queryParams completion:(void (^)(UIViewController *))completion{
    
    BOOL canOpen = NO;
    
    NSString *targetRoutePattern = *routePattern;
    
    NSDictionary *targetQueryParams = *queryParams;
    
    NSArray *pathComponents = [self pathComponentsFromRoutePattern:targetRoutePattern];
    
    NSString *components = [pathComponents componentsJoinedByString:@"."];
    
    id routesValue = self.routesDictionary[components];
    
    NSString *targetControllerName = nil;
    NSDictionary *controllerHandler = nil;
    
    if ([routesValue isKindOfClass:[NSString class]]) {
        targetControllerName = (NSString *)routesValue;
    }else if ([routesValue isKindOfClass:[NSDictionary class]]) {
        controllerHandler = (NSDictionary *)routesValue;
        targetControllerName = controllerHandler.allKeys.firstObject;
    }
    
    Class targetClass = NSClassFromString(targetControllerName);
    UIViewController *targetController = [[targetClass alloc] init];
    if ([targetController respondsToSelector:@selector(setParamsDictionary:)]) {
        [targetController performSelector:@selector(setParamsDictionary:) withObject:targetQueryParams];
    }
    
    if (targetController) {
        if (controllerHandler) {
            HandlerBlock handlerBlock = [controllerHandler valueForKey:targetControllerName];
            
            if (handlerBlock) {
                targetController.handlerBlock = handlerBlock;
            }
        }
        
        //push
        if (completion) {
            completion(targetController);
        }else{
            [self pushTargetController:targetController];
        }
        canOpen = YES;
    }else{
        NSLog(@"未找到相关类!");
    }
    
    return canOpen;
}

- (void)pushTargetController:(UIViewController *)targetController {
    if (self.currentController.navigationController) {
        [self.currentController.navigationController pushViewController:targetController animated:YES];
    }else{
        [self.currentController presentViewController:targetController animated:YES completion:^{
            NSLog(@"打开成功");
        }];
    }
    
}

#pragma mark - 其他
- (NSMutableDictionary *)routesDictionary {
    if (!_routesDictionary) {
        NSMutableDictionary *routesDictionary = [NSMutableDictionary dictionary];
        _routesDictionary = routesDictionary;
    }
    return _routesDictionary;
}

- (BOOL)isVaildScheme:(NSString *)scheme {
    if (!scheme) {
        return NO;
    }
    return [self.allowSchemes containsObject:scheme];
}

- (NSMutableArray *)allowSchemes {
    if (!_allowSchemes) {
        NSMutableArray *allowSchemes = [NSMutableArray array];
        _allowSchemes = allowSchemes;
    }
    return _allowSchemes;
}

- (void)configAllowSchemes:(NSArray *)schemes {
    if (schemes && schemes.count > 0) {
        [schemes enumerateObjectsUsingBlock:^(NSString *  _Nonnull scheme, NSUInteger idx, BOOL * _Nonnull stop) {
            [self.allowSchemes addObject:scheme];
        }];
    }
}

@end
