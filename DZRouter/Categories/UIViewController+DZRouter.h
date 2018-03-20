//
//  UIViewController+DZRouter.h
//  DZRouter
//
//  Created by 张国忠 on 2018/3/20.
//  Copyright © 2018年 张国忠. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void(^HandlerBlock)(NSString *handlerTag, id results);

@interface UIViewController (DZRouter)

@property(nonatomic,copy) HandlerBlock handlerBlock;

@property(nonatomic,copy) NSDictionary *paramsDictionary;

@end
