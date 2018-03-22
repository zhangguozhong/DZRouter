# DZRouter
封装好的简单URL Router中间件，用于解耦，借鉴网络上大神的思路加入自己的一些思路与想法，目的在于学习组件化思想该如何应用。


### 配置Schemes与Routers
```objective-c
    // 配置schemes，用于判断路由是否是合法的路由；
    [[DZRouter sharedDZRouter] configAllowSchemes:@[@"myapp",@"zhangsan"]];
    
    // 初始化路由，读取的是routes.plist文件
    [DZRouter registerRoutePatterns];
```


### 使用
```objective-c

// block回调，跳转页面，跳转方式自己决定；
[DZRouter registerRoutePattern:@"myapp://Amodule/mall/detail" targetControllerName:@"BTestViewController"];
    [DZRouter startRoute:@"myapp://Amodule/mall/detail?info1=RouterDemo&info2=dgfs&info3=123456789" completion:^(UIViewController *targetController) {
        [self.navigationController pushViewController:targetController animated:YES];
    }];
    
// 中间组件内部决定，跳转页面，优先push，其次present；
[DZRouter registerRoutePattern:@"myapp://Bmodule/mall/list" targetControllerName:@"DTestViewController" handler:^(NSString *handlerTag, id parameters) {
        NSLog(@"pushC button click");
    }];
[DZRouter startRoute:@"myapp://Bmodule/mall/list"];
```

### 总结

1、之前一直在纠结，push与present跳转逻辑如何设计：（1）是封装在中间件的逻辑，（2）是留一个回调让开发者自行决定选择何种方式；细细想过之后却发现这个问题不需要这个中间件组件中考虑，因为大家想想看减少耦合是组件化的要实现的目标，即不需要引入头文件就能使用该文件。因此ViewController中存在`[self.navigationController pushViewController:targetController animated:YES];`的代码并不增加耦合度，然而选择第（2）种方式跳转的逻辑会更加清晰；


2、因此设计时加上completion回调，专门用来执行push或者是present跳转界面逻辑的。


