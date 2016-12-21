# NoUMShare
> qq、微信、新浪微博分享、登录非友盟封装

##准备工作
> 为以后方便更新第三方社交平台的sdk，所以封装里不包含QQ、微信、微博等第三方平台的sdk。

1. 使用前需先按照QQ、微信、微博开发平台的相关文档集成需要的sdk到工程中。

	-  [QQ开发文档地址](http://wiki.open.qq.com/wiki/IOS_API调用说明)
	-  [微信开发文档地址](https://open.weixin.qq.com/cgi-bin/showdocument?action=dir_list&t=resource/res_list&verify=1&id=1417694084&token=4683a2e8ad1ac447ed5aa4557bf6f4758d76c908&lang=zh_CN)
	-  [微博开发文档地址](http://open.weibo.com/wiki/移动应用介绍) (最坑的文档没有之一)

2. 下载并集成ShareManager
	- ManagerVO.h .m
	- ShareManager.h .m
	- ShareNetWork.h .m

3. 编译，检查集成是否完整。

##使用
###初始化

在ShareManager.h中配置各种key

```objc
#define WeiBo_AppKey         @""
#define WeiBo_RedirectURI    @"https://sns.whalecloud.com/sina2/callback"

#define WeiXin_AppKey        @""
#define WeiXin_Secret        @""

#define Tencent_AppKey       @""
#define Tencent_RedirectURI  @"www.qq.com"
```
在AppDelegate.m中添加初始化代码

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    //所有第三方平台的初始化都放到了这个方法中
    [ShareManager shareManager];
    return YES;
}
- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
	//如果有其他sdk 请写在最后
    return [ShareManager handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	//如果有其他sdk 请写在最后
    return [ShareManager handleOpenURL:url];
}
```

###分享
**ShareVO** 为分享内容的实例对象，调用分享前须先创建ShareVO对象，并设置回调函数

```objc
	//创建分享实例对象
    ShareVO *shareVO = [[ShareVO alloc] init];
    //分享平台（必须）
    shareVO.platform = self.segment.selectedSegmentIndex;
    //分享标题（必须）
    shareVO.title = @"lalalalala";
    //分享描述（可选）需要描述但没有填写时会将标题作为描述
    shareVO.des = @"这是一个超越 UM 的封装";
    //分享图片/缩略图（可选）不填写则只分享文字
    shareVO.image = @"https://img0.bdstatic.com/static/searchdetail/img/logo-2X_b99594a.png";
    //分享链接（可选）不填写则只分享图片或文字
    shareVO.link = @"https://www.baidu.com";
    //分享所在vc（如果使用短信、邮箱分享则必填，否则可选）
    shareVO.rootVC = self;
    //设置分享回调函数 ⚠️ 这个必须有，且不能为nil
    [shareVO shareComplate:^(NSString *message, AuthorizeVO *userInfo) {
    	//只要message不为nil，即为分享失败，message为失败原因
        if (message) {
            NSLog(@"%@",message);
        }else
        {
            NSLog(@"分享成功");
        }
    }];
```

创建好ShareVO对象后调用ShareManager的类方法将ShareVO对象作为参数调起对应分享功能

```objc
	[ShareManager shareWith:shareVO];
```

###登录/绑定
调用第三方登录使用ShareManager的类方法调用即可

```objc
	//platform 登录平台
	[ShareManager logInWith:platform and:^(NSString *message, 	AuthorizeVO *userInfo) {
		//只要message不为nil，即为登录失败，message为失败原因
        if (message) {
            NSLog(@"%@",message);
        }else
        {
        	//登录成功后会返回AuthorizeVO对象，其中包含需要的第三方登录账号相关信息
            NSLog(@"%@",userInfo);
        }
    }];
```

###单个平台登出/解绑
调用第三方登出使用ShareManager的类方法调用即可

```objc
	//platform 登录平台
	[ShareManager logOutWith:platform and:^(NSString *message, 	AuthorizeVO *userInfo) {
		//退出登录一定成功，不会失败，block会立即被调用，相当于同步
    }];
```

###全部登出/解绑
调用第三方全部登出使用ShareManager的类方法调用即可

```objc
	[ShareManager logOutAllPlatform:^(NSString *message, AuthorizeVO *userInfo) {
        //退出登录一定成功，不会失败，block会立即被调用，相当于同步
    }];
```

> ##整体结构
###ManagerVO.h
ManagerVO.h为分享、登录结果的model
###ShareNetWork.h
ShareNetWork.h网络请求工具类
###ShareManager.h
ShareManager.h为主体，负责API的调用，将ManagerVO.h与ShareNetWork.h相结合完成相关功能。

##后期计划
- 添加多媒体分享
- 添加更多状态回调函数
- 解决与微信支付的冲突
- 将各平台分离，做到可以单个集成
- 结构、性能优化
- 。。。

> 业余时间做的小工具，欢迎各种建议👏