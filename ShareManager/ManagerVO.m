//
//  ManagerVO.m
//  ShareLxc
//
//  Created by Mr.S on 2016/12/20.
//  Copyright © 2016年 梁新昌. All rights reserved.
//

#import "ManagerVO.h"
#import "WeiboUser.h"

#pragma mark ManagerVO
@interface ManagerVO ()

@end

@implementation ManagerVO

@end

#pragma mark ShareVO
@interface ShareVO ()

@end

@implementation ShareVO

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.title = @"";
        self.des = @"";
        [self shareComplate:^(NSString *message, AuthorizeVO *userInfo) {
            
        }];
    }
    return self;
}

-(BOOL)prepareToShare
{
    if ([self.image isKindOfClass:[NSString class]]) {
        self.image = [self getImageFromURL:self.image];
    }else if ([self.image isKindOfClass:[UIImage class]]) {
        self.image = UIImageJPEGRepresentation(self.image, 1.0);
    }
    return YES;
}

-(void)compressImage
{
    CGFloat max = 800;
    UIImage* image = [UIImage imageWithData:self.image];
    CGFloat width  = image.size.width;
    CGFloat height = image.size.height;
    CGSize size;
    
    if (width > height) {
        if (width <= max) {
            return;
        }else
        {
            float hw = height/width;
            size = CGSizeMake(max, max*hw);
        }
    }else
    {
        if (height <= max) {
            return;
        }else
        {
            float wh = width/height;
            size = CGSizeMake(wh * max, max);
        }
    }
    
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0,0, size.width, size.height)];
    UIImage *newImage =UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    self.image = UIImageJPEGRepresentation(newImage,1);
}

-(void)shareComplate:(ShareResultCallBack)onComplete
{
    self.callBack = onComplete;
}

//获取网络图片
-(NSData *) getImageFromURL:(NSString *)fileURL {
    NSData* data = [NSData dataWithContentsOfURL:[NSURL URLWithString:fileURL]];
    return data;
}

@end

#pragma mark AuthorizeVO
@interface AuthorizeVO ()

@end

@implementation AuthorizeVO

+(instancetype)authorizeWithPlatform:(PlatformType)type andData:(id)data
{
    AuthorizeVO * authorize = [[AuthorizeVO alloc]init];
    switch (type) {
        case wechat:
            [authorize fillWithWeixinData:data];
            break;
            
        case weibo:
            [authorize fillWithWeiboData:data];
            break;
            
        case qq:
            [authorize fillWithQQData:data];
            break;
            
        default:
            break;
    }
    return authorize;
}

-(void)fillWithWeiboData:(id)data{
    if ([data isKindOfClass:[WBAuthorizeResponse class]]) {
        WBAuthorizeResponse* authorizeResponse = (WBAuthorizeResponse *)data;
        self.userID = authorizeResponse.userID;
        self.accessToken = authorizeResponse.accessToken;
        self.expirationDate = authorizeResponse.expirationDate;
        self.refreshToken = authorizeResponse.refreshToken;
    }
}

-(void)fillWithWeixinData:(id)data{
    NSDictionary* userData = (NSDictionary *)data;
    self.accessToken = userData[@"access_token"];
    self.expirationDate = userData[@"expires_in"];
    self.refreshToken = userData[@"refresh_token"];
    self.openId = userData[@"openid"];
    self.userID = userData[@"unionid"];
}

-(void)fillWithQQData:(id)data{
    TencentOAuth* auth = (TencentOAuth *)data;
    self.openId = auth.openId;
    self.userID = auth.unionid;
    self.accessToken = auth.accessToken;
}

-(void)fillWithPlatform:(PlatformType)type andUser:(id)user
{
    switch (type) {
        case wechat:
            [self fillWithWeixinUser:user];
            break;
            
        case weibo:
            [self fillWithWeiboUser:user];
            break;
            
        case qq:
            [self fillWithQQUser:user];
            break;
            
        default:
            break;
    }
}

-(void)fillWithWeiboUser:(id)user{
    if ([user isKindOfClass:[WeiboUser class]]) {
        WeiboUser* authorizeResponse = (WeiboUser *)user;
        self.name = authorizeResponse.name;
        self.headImg = authorizeResponse.profileImageUrl;
        self.userID = authorizeResponse.userID;
    }
}

-(void)fillWithWeixinUser:(id)user{
    NSDictionary* userData = (NSDictionary *)user;
    self.name = userData[@"nickname"];
    self.headImg = userData[@"headimgurl"];
    self.userID = userData[@"unionid"];
}

-(void)fillWithQQUser:(id)user{
    NSDictionary* userDic = [(APIResponse *)user jsonResponse];
    self.name = userDic[@"nickname"];
}

@end
