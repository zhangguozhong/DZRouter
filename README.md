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
减少耦合是组件化的主要目的，即不需要引入文件。因此ViewController中存在`[self.navigationController pushViewController:targetController animated:YES];`的代码，并不增加耦合度，跳转的逻辑却更加清晰。


