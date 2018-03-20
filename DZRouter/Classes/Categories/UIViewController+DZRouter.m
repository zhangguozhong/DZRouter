//
//  UIViewController+DZRouter.m
//  DZRouter
//
//  Created by 张国忠 on 2018/3/20.
//  Copyright © 2018年 张国忠. All rights reserved.
//

#import "UIViewController+DZRouter.h"
#import <objc/runtime.h>

@implementation UIViewController (DZRouter)

- (HandlerBlock)handlerBlock {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setHandlerBlock:(HandlerBlock)handlerBlock {
    objc_setAssociatedObject(self, @selector(handlerBlock), handlerBlock, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (NSDictionary *)paramsDictionary {
    return objc_getAssociatedObject(self, _cmd);
}

- (void)setParamsDictionary:(NSDictionary *)paramsDictionary {
    objc_setAssociatedObject(self, @selector(paramsDictionary), paramsDictionary, OBJC_ASSOCIATION_COPY_NONATOMIC);
}

@end
