//
//  ManagerVO.h
//  ShareLxc
//
//  Created by Mr.S on 2016/12/20.
//  Copyright © 2016年 梁新昌. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "WeiboSDK.h"
#import "WeiboSDK+Statistics.h"
#import "WXApi.h"
#import <TencentOpenAPI/TencentOAuth.h>

@interface ManagerVO : NSObject

@end

/**
 * @brief 分享平台类型
 */
typedef NS_ENUM(NSInteger, PlatformType) {
    wechat          = 0, //微信
    wechat_circle   = 1, //微信朋友圈
    qq              = 2, //QQ
    qzone           = 3, //QQ空间
    weibo           = 4, //新浪微博
    message         = 5, //短信
    email           = 6, //邮箱
};

/**
 * @brief 授权内容实例
 */
@interface AuthorizeVO : ManagerVO

@property (strong,nonatomic) NSString         *    userID;
@property (strong,nonatomic) NSString         *    openId;
@property (strong,nonatomic) NSString         *    accessToken;
@property (strong,nonatomic) id                    expirationDate;
@property (strong,nonatomic) NSString         *    refreshToken;
@property (strong,nonatomic) NSString         *    name;
@property (strong,nonatomic) NSString         *    headImg;

+(instancetype)authorizeWithPlatform:(PlatformType)type andData:(id)data;
-(void)fillWithPlatform:(PlatformType)type andUser:(id)user;

@end

/**
 * @brief  分享回调
 *
 * @param  message 错误信息.
 */
typedef void (^ShareResultCallBack)(NSString * message ,AuthorizeVO * userInfo);

/**
 * @brief 分享内容实例
 */
@interface ShareVO : ManagerVO

@property (strong,nonatomic) NSString         *    title;       //分享标题
@property (strong,nonatomic) NSString         *    des;         //分享描述
@property (strong,nonatomic) NSString         *    link;        //分享链接
@property (strong,nonatomic) id                    image;       //分享图片
@property (strong,nonatomic) UIViewController *    rootVC;      //VC
@property (assign,nonatomic) PlatformType          platform;    //分享平台
@property (copy  ,nonatomic) ShareResultCallBack   callBack;    //分享回调函数

-(void)shareComplate:(ShareResultCallBack)onComplete;
-(BOOL)prepareToShare;
@end
