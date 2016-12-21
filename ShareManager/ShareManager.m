//
//  ShareManager.m
//  ShareLxc
//
//  Created by Mr.S on 2016/12/19.
//  Copyright © 2016年 梁新昌. All rights reserved.
//

#import "ShareManager.h"
#import "ShareNetWork.h"
#import <MessageUI/MessageUI.h>
#import <TencentOpenAPI/TencentMessageObject.h>
#import <TencentOpenAPI/TencentApiInterface.h>
#import <TencentOpenAPI/QQApiInterface.h>
#import <TencentOpenAPI/QQApiInterfaceObject.h>

#define Weibo_Token @"weibo_token"

@interface ShareManager ()<MFMessageComposeViewControllerDelegate,MFMailComposeViewControllerDelegate, WeiboSDKDelegate, WXApiDelegate, TencentLoginDelegate, TencentSessionDelegate,WBHttpRequestDelegate> {
    
}

@property TencentOAuth *tencentOAuth;
@property enum WXScene scene;

@end

@implementation ShareManager

+(instancetype)shareManager
{
    static ShareManager* share = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        share = [[ShareManager alloc]init];
        //微博初始化
        [WeiboSDK enableDebugMode:YES];
        [WeiboSDK registerApp:WeiBo_AppKey];
        [WXApi registerApp:WeiXin_AppKey withDescription:@"都市频道"];
        
    });
    return share;
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.tencentOAuth = [[TencentOAuth alloc] initWithAppId:Tencent_AppKey andDelegate:self];
        self.tencentOAuth.redirectURI = Tencent_RedirectURI;
    }
    return self;
}

+(BOOL)handleOpenURL:(NSURL *)url
{
    if ([WeiboSDK handleOpenURL:url delegate:[ShareManager shareManager]]) {
        return YES;
    } else if ([WXApi handleOpenURL:url delegate:[ShareManager shareManager]]) {
        return YES;
    } else if ([TencentOAuth HandleOpenURL:url]) {
        /**
         处理由手Q唤起的跳转请求
         \param url 待处理的url跳转请求
         \param delegate 第三方应用用于处理来至QQ请求及响应的委托对象
         \return 跳转请求处理结果，YES表示成功处理，NO表示不支持的请求协议或处理失败
         */
        if ([url.absoluteString hasPrefix:[NSString stringWithFormat:@"tencent%@",Tencent_AppKey]]) {
            [QQApiInterface handleOpenURL:url delegate:[ShareManager shareManager]];
            return [TencentOAuth HandleOpenURL:url];
        }
        return YES;
    } else {
        return NO;
    }
    
}

#pragma mark 登录
+(BOOL)logInWith:(PlatformType)platform and:(ShareResultCallBack)callBack
{
    ShareManager* manager = [ShareManager shareManager];
    switch (platform) {
        case wechat:
            manager.callBack = callBack;
            return [manager loginWithWechat];
        case qq:
            manager.callBack = callBack;
            return [manager loginWithQQ];
        case weibo:
            manager.callBack = callBack;
            return [manager loginWithWeibo];
        default:
            manager.callBack = nil;
            return NO;
            break;
    }
}

-(BOOL)loginWithWechat{
    SendAuthReq* req =[[SendAuthReq alloc ] init ];
    req.scope = @"snsapi_userinfo";
    //第三方向微信终端发送一个SendAuthReq消息结构
    return [WXApi sendReq:req];
}
-(BOOL)loginWithQQ{
    NSArray* permissions = [NSArray arrayWithObjects:
                            kOPEN_PERMISSION_GET_USER_INFO,
                            kOPEN_PERMISSION_GET_SIMPLE_USER_INFO,
                            kOPEN_PERMISSION_ADD_SHARE,
                            nil];
    [self.tencentOAuth authorize:permissions];
    return YES;
}
-(BOOL)loginWithWeibo{
    WBAuthorizeRequest* request = [WBAuthorizeRequest request];
    request.redirectURI = WeiBo_RedirectURI;
    request.scope = @"all";
    [WeiboSDK sendRequest:request];
    return YES;
}

#pragma mark 取消绑定
+(BOOL)logOutWith:(PlatformType)platform and:(ShareResultCallBack)callBack
{
    ShareManager* manager = [ShareManager shareManager];
    switch (platform) {
        case wechat:
            manager.callBack = callBack;
            [manager logoutWithWechat];
        case qq:
            manager.callBack = callBack;
            [manager logoutWithQQ];
        case weibo:
            manager.callBack = callBack;
            [manager logoutWithWeibo];
        default:
            manager.callBack = nil;
    }
    callBack(nil,nil);
    return YES;
}

+(BOOL)logOutAllPlatform:(ShareResultCallBack)callBack
{
    ShareManager* manager = [ShareManager shareManager];
    manager.callBack = callBack;
    [manager logoutWithWechat];
    [manager logoutWithQQ];
    [manager logoutWithWeibo];
    manager.callBack(nil,nil);
    manager.callBack = nil;
    return YES;
}

-(BOOL)logoutWithWechat{
    
    return YES;
}
-(BOOL)logoutWithQQ{
    [self.tencentOAuth logout:self];
    return YES;
}
-(BOOL)logoutWithWeibo{
    NSString* weiboToken = [ShareNetWork getObjectWithKey:Weibo_Token];
    if (weiboToken) {
        [WeiboSDK logOutWithToken:Weibo_Token delegate:self withTag:nil];
    }
    return YES;
}

#pragma mark 分享
+(BOOL)shareWith:(ShareVO *)share
{
    if (share) {
        if (share.title && share.title.length > 0) {
            ShareManager* manager = [ShareManager shareManager];
            return [manager shareWith:share];
        }else
        {
            NSLog(@"标题不能为空");
            return NO;
        }
    }else
    {
        NSLog(@"需先创建ShareVO对象");
        return NO;
    }
}

-(BOOL)shareWith:(ShareVO *)share{
    BOOL success = share;
    self.callBack = share.callBack;
    self.rootVC = share.rootVC;
    [share prepareToShare];
    switch (share.platform) {
        case wechat:
            [self shareToWechat:share];
            break;
        case wechat_circle:
            [self shareToWechatCircle:share];
            break;
        case qq:
            [self shareToQQ:share];
            break;
        case qzone:
            [self shareToQzone:share];
            break;
        case weibo:
            [self shareToWeibo:share];
            break;
        case message:
            [self shareToMessage:share];
            break;
        case email:
            [self shareToEmail:share];
            break;
    }
    
    return success;
}

//微信分享
-(BOOL)shareToWechat:(ShareVO *)share{
    BOOL success = share;
    _scene = WXSceneSession;
    if (share.link) {
        [self sendLinkContent:share];
    } else if (share.image) {
        [self sendImageContent:share];
    } else {
        [self sendTextContent:share];
    }
    
    return success;
}

//朋友圈分享
-(BOOL)shareToWechatCircle:(ShareVO *)share{
    BOOL success = share;
    _scene = WXSceneTimeline;
    if (share.link) {
        [self sendLinkContent:share];
    } else if (share.image) {
        [self sendImageContent:share];
    } else {
        [self sendTextContent:share];
    }
    
    return success;
}

//QQ分享
-(BOOL)shareToQQ:(ShareVO *)share{
    BOOL success = share;
    if (share.link) {
        [self sendNewsMessageWithLocalImage:share];
    } else if (share.image) {
        [self sendImageMessage:share];
    } else {
        [self sendTextMessage:share];
    }
    return success;
}

//QQ空间分享
-(BOOL)shareToQzone:(ShareVO *)share{
    BOOL success = share;
    if (share.link) {
        [self sendNewsMessageWithLocalImage:share];
    } else {
        [self shareToQQ:share];
    }
    return success;
}

//微博分享
-(BOOL)shareToWeibo:(ShareVO *)share{
    BOOL success = share;
    
    WBAuthorizeRequest *authRequest = [WBAuthorizeRequest request];
    authRequest.redirectURI = WeiBo_RedirectURI;
    authRequest.scope = @"all";
    
    WBSendMessageToWeiboRequest *request = [WBSendMessageToWeiboRequest requestWithMessage:[self messageToShare:share] authInfo:authRequest access_token:nil];
    
    [WeiboSDK sendRequest:request];
    
    
    return success;
}

//短信分享
-(BOOL)shareToMessage:(ShareVO *)share{
    BOOL success = share;
    
    Class messageClass = (NSClassFromString(@"MFMessageComposeViewController"));
    
    if (messageClass != nil) {
        if ([messageClass canSendText]) {
            MFMessageComposeViewController *picker = [[MFMessageComposeViewController alloc] init];
            picker.messageComposeDelegate =self;
            NSString *smsBody =[NSString stringWithFormat:@"%@ %@", share.title,share.link] ;
            picker.body=smsBody;
            [self.rootVC presentViewController:picker animated:YES completion:^{
                
            }];
        }
        else {
            return NO;
        }
    }
    else {
        return NO;
    }
    
    return success;
}

//邮箱分享
-(BOOL)shareToEmail:(ShareVO *)share{
    BOOL success = share;
    
    Class mailClass = (NSClassFromString(@"MFMailComposeViewController"));
    
    if (mailClass !=nil) {
        if ([mailClass canSendMail]) {
            MFMailComposeViewController *picker = [[MFMailComposeViewController alloc] init];
            
            picker.mailComposeDelegate =self;
            [picker setSubject:share.title];
            
            NSString *emailBody =[NSString stringWithFormat:@"%@ %@",share.des,share.link] ;
            [picker setMessageBody:emailBody isHTML:NO];
            [self.rootVC presentViewController:picker animated:YES completion:^{
                
            }];
        }else{
            return NO;
        }
    }else{
        return NO;
    }
    
    return success;
}

#pragma mark QQSDK回调函数
- (void)tencentDidLogin
{
    [self.tencentOAuth RequestUnionId];
}
- (void)tencentDidNotLogin:(BOOL)cancelled
{
    if (cancelled) {
        self.callBack(@"已取消",nil);
    }else
    {
        self.callBack(@"登录失败",nil);
    }
}
- (void)tencentDidNotNetWork
{
    self.callBack(@"网络连接错误",nil);
}
-(void)didGetUnionID
{
    if (![self.tencentOAuth getUserInfo]) {
        self.callBack(@"登录失败",nil);
    }
}
- (void)getUserInfoResponse:(APIResponse*) response
{
    AuthorizeVO* authorize = [AuthorizeVO authorizeWithPlatform:qq andData:self.tencentOAuth];
    [authorize fillWithPlatform:qq andUser:response];
    self.callBack(nil,authorize);
}

#pragma mark 微博SDK回调函数 <WeiboSDKDelegate>
- (void)didReceiveWeiboResponse:(WBBaseResponse *)response
{
    if (response.statusCode == WeiboSDKResponseStatusCodeSuccess) {
        if ([response isKindOfClass:[WBAuthorizeResponse class]]) {
            __block AuthorizeVO * authorize = [AuthorizeVO authorizeWithPlatform:weibo andData:response];
            [WBHttpRequest requestForUserProfile:authorize.userID withAccessToken:authorize.accessToken andOtherProperties:nil queue:[NSOperationQueue mainQueue] withCompletionHandler:^(WBHttpRequest *httpRequest, id result, NSError *error) {
                if (error) {
                    self.callBack(@"获取用户信息失败",nil);
                }else
                {
                    [authorize fillWithPlatform:weibo andUser:result];
                    [ShareNetWork saveObject:authorize.accessToken withKey:Weibo_Token];
                    self.callBack(nil,authorize);
                }
            }];
        } else {
            self.callBack(nil, nil);
        }
        
        
    } else if (response.statusCode == WeiboSDKResponseStatusCodeUserCancel) {
        self.callBack(@"已取消",nil);
    } else  {
        self.callBack(@"操作失败",nil);
    }
    
}

- (void)didReceiveWeiboRequest:(WBBaseRequest *)request
{
}

- (WBMessageObject *)messageToShare:(ShareVO *)share
{
    WBMessageObject *message = [WBMessageObject message];
    if (share.image) {
        WBImageObject *image = [WBImageObject object];
        image.imageData = share.image;
        message.imageObject = image;
        message.text = [NSString stringWithFormat:@"%@ %@", share.title, share.link];
    } else {
        message.text = [NSString stringWithFormat:@"%@ %@", share.title, share.link];
    }
    
    return message;
}

#pragma mark 短信分享
-(void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult)result
{
    [self.rootVC dismissViewControllerAnimated:YES completion:nil];
    switch (result) {
        case MessageComposeResultSent:
            self.callBack(nil,nil);
            break;
        case MessageComposeResultFailed:
            self.callBack(@"信息传送失败",nil);
            break;
        case MessageComposeResultCancelled:
            self.callBack(@"信息被用户取消传送",nil);
            break;
        default:
            break;
    }
}

#pragma mark 邮件分享
- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(nullable NSError *)error
{
    [self.rootVC dismissViewControllerAnimated:YES completion:nil];
    switch (result)
    {
        case MFMailComposeResultCancelled:
            self.callBack(@"信息被用户取消传送",nil);
            break;
        case MFMailComposeResultSaved:
            self.callBack(@"信息被保存",nil);
            break;
        case MFMailComposeResultSent:
            self.callBack(nil,nil);
            break;
        case MFMailComposeResultFailed:
            self.callBack(@"信息传送失败",nil);
            break;
        default:
            break;
    }
}
#pragma mark - 微信 及 朋友圈分享
// QQ 和微信都会掉这两个方法
-(void) onReq:(BaseReq*)req
{
    
    
}
-(void) onResp:(BaseResp*)resp
{
    switch (resp.errCode)
    {
        case 0:
            if (![resp isKindOfClass:[SendAuthResp class]]) {
                self.callBack(nil,nil);
            }else
            {
                SendAuthResp* authResp = (SendAuthResp *)resp;
                [ShareNetWork getWith:[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/oauth2/access_token?appid=%@&secret=%@&code=%@&grant_type=authorization_code",WeiXin_AppKey,WeiXin_Secret,authResp.code] completionHandler:^(NSDictionary *data, NSError *error) {
                    if (error) {
                        self.callBack(@"登录失败",nil);
                    }else
                    {
                        AuthorizeVO* authorize = [AuthorizeVO authorizeWithPlatform:wechat andData:data];
                        [ShareNetWork getWith:[NSString stringWithFormat:@"https://api.weixin.qq.com/sns/userinfo?access_token=%@&openid=%@",authorize.accessToken,authorize.openId] completionHandler:^(NSDictionary *data, NSError *error) {
                            if (error) {
                                self.callBack(@"登录失败",nil);
                            }else
                            {
                                [authorize fillWithPlatform:wechat andUser:data];
                                self.callBack(nil,authorize);
                            }
                        }];
                    }
                }];
            }
            break;
        case -1:
            self.callBack(@"操作失败",nil);
            break;
        case -2:
            self.callBack(@"已取消",nil);
            break;
        case -3:
            self.callBack(@"发送失败",nil);
            break;
        case -4:
            self.callBack(@"授权失败",nil);
            break;
        case -5:
            self.callBack(@"微信不支持",nil);
            break;
        default:
            break;
    }
    
}
// 下面是微信的发送内容 (包括文本,图片,链接)
- (void) sendTextContent:(ShareVO *)share
{
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.text = share.des;
    req.bText = YES;
    req.scene = _scene;
    [WXApi sendReq:req];
}

-(void) RespTextContent:(ShareVO *)share
{
    GetMessageFromWXResp* resp = [[GetMessageFromWXResp alloc] init];
    resp.text = share.des;
    resp.bText = YES;
    
    [WXApi sendResp:resp];
}

- (void) sendImageContent:(ShareVO *)share
{
    WXMediaMessage *message = [WXMediaMessage message];
    [message setThumbImage:[UIImage imageWithData:share.image]];
    
    WXImageObject *ext = [WXImageObject object];
    ext.imageData = share.image;
    UIImage* image = [UIImage imageWithData:ext.imageData];
    ext.imageData = UIImagePNGRepresentation(image);
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = _scene;
    [WXApi sendReq:req];
}

- (void) RespImageContent:(ShareVO *)share
{
    WXMediaMessage *message = [WXMediaMessage message];
    [message setThumbImage:[UIImage imageWithData:share.image]];
    
    WXImageObject *ext = [WXImageObject object];
    ext.imageData = share.image;
    message.mediaObject = ext;
    
    GetMessageFromWXResp* resp = [[GetMessageFromWXResp alloc] init];
    resp.message = message;
    resp.bText = NO;
    
    [WXApi sendResp:resp];
}

- (void) sendLinkContent:(ShareVO *)share
{
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = share.title;
    message.description = share.des;
    [message setThumbImage:[UIImage imageWithData:share.image]];
    
    WXWebpageObject *ext = [WXWebpageObject object];
    ext.webpageUrl = share.link;
    
    message.mediaObject = ext;
    
    SendMessageToWXReq* req = [[SendMessageToWXReq alloc] init];
    req.bText = NO;
    req.message = message;
    req.scene = _scene;
    [WXApi sendReq:req];
}

-(void) RespLinkContent:(ShareVO *)share
{
    WXMediaMessage *message = [WXMediaMessage message];
    message.title = share.title;
    message.description = share.des;
    [message setThumbImage:[UIImage imageWithData:share.image]];
    
    WXWebpageObject *ext = [WXWebpageObject object];
    ext.webpageUrl = share.link;
    
    message.mediaObject = ext;
    
    GetMessageFromWXResp* resp = [[GetMessageFromWXResp alloc] init];
    resp.message = message;
    resp.bText = NO;
    
    [WXApi sendResp:resp];
}
#pragma mark - QQ 和 QQ空间
// 发送内容(文本,图片,链接)
- (void) sendTextMessage:(ShareVO *)share
{
    
    QQApiTextObject* txtObj = [QQApiTextObject objectWithText:share.title];
    SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:txtObj];
    
    if (share.platform == qq) {
        QQApiSendResultCode sentQ = [QQApiInterface sendReq:req];
        [self handleSendResult:sentQ];
    } else {
        QQApiSendResultCode sentQZone = [QQApiInterface SendReqToQZone:req];
        [self handleSendResult:sentQZone];
    }
    
}

- (void) sendImageMessage:(ShareVO *)share
{
    
    QQApiImageObject* img = [QQApiImageObject objectWithData:share.image previewImageData:share.image title:share.title description:share.des];
    SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:img];
    
    if (share.platform == qq) {
        QQApiSendResultCode sentQ = [QQApiInterface sendReq:req];
        [self handleSendResult:sentQ];
    } else {
        QQApiSendResultCode sentQZone = [QQApiInterface SendReqToQZone:req];
        [self handleSendResult:sentQZone];
    }
    
    
    
}
- (void) sendNewsMessageWithLocalImage:(ShareVO *)share
{
    NSURL* url = [NSURL URLWithString:share.link];
    
    QQApiNewsObject* img = [QQApiNewsObject objectWithURL:url title:share.title description:share.des previewImageData:share.image];
    SendMessageToQQReq* req = [SendMessageToQQReq reqWithContent:img];
    
    if (share.platform == qq) {
        QQApiSendResultCode sentQ = [QQApiInterface sendReq:req];
        [self handleSendResult:sentQ];
    } else {
        QQApiSendResultCode sentQZone = [QQApiInterface SendReqToQZone:req];
        [self handleSendResult:sentQZone];
    }
    
}
- (void)sendMusicMessage:(ShareVO *)share {
    //分享跳转URL
    NSString *url = @"http://xxx.xxx.xxx/";
    //分享图预览图URL地址
    NSString *previewImageUrl = @"preImageUrl.png";
    //音乐播放的网络流媒体地址
    NSString *flashURL = @"xxx.mp3 ";
    QQApiAudioObject *audioObj =[QQApiAudioObject
                                 objectWithURL :[NSURL URLWithString:url]
                                 title:@"title"
                                 description:@"description"
                                 previewImageURL:[NSURL URLWithString:previewImageUrl]];
    //设置播放流媒体地址
    [audioObj setFlashURL:[NSURL URLWithString:flashURL]];
    SendMessageToQQReq *req = [SendMessageToQQReq reqWithContent:audioObj];
    
    if (share.platform == qq) {
        QQApiSendResultCode sentQ = [QQApiInterface sendReq:req];
        [self handleSendResult:sentQ];
    } else {
        QQApiSendResultCode sentQZone = [QQApiInterface SendReqToQZone:req];
        [self handleSendResult:sentQZone];
    }
}
//返回错误方法
- (void)handleSendResult:(QQApiSendResultCode)sendResult
{
    switch (sendResult)
    {
        case EQQAPIAPPNOTREGISTED:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"App未注册" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            
            break;
        }
        case EQQAPIMESSAGECONTENTINVALID:
        case EQQAPIMESSAGECONTENTNULL:
        case EQQAPIMESSAGETYPEINVALID:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"发送参数错误" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            
            break;
        }
        case EQQAPIQQNOTINSTALLED:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"未安装手Q" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            
            break;
        }
        case EQQAPIQQNOTSUPPORTAPI:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"API接口不支持" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            
            break;
        }
        case EQQAPISENDFAILD:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"发送失败" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            
            break;
        }
        case EQQAPIVERSIONNEEDUPDATE:
        {
            UIAlertView *msgbox = [[UIAlertView alloc] initWithTitle:@"Error" message:@"当前QQ版本太低，需要更新" delegate:nil cancelButtonTitle:@"取消" otherButtonTitles:nil];
            [msgbox show];
            break;
        }
        default:
        {
            break;
        }
    }
}


@end
