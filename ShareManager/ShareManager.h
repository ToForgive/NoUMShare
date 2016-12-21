//
//  ShareManager.h
//  ShareLxc
//
//  Created by Mr.S on 2016/12/19.
//  Copyright © 2016年 梁新昌. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ManagerVO.h"

#define WeiBo_AppKey         @"1544071096"
#define WeiBo_RedirectURI    @"https://sns.whalecloud.com/sina2/callback"

#define WeiXin_AppKey        @"wx9b3b786aee9d0535"
#define WeiXin_Secret        @"33416ca264ada84c703518684d488031"

#define Tencent_AppKey       @"1104637455"
#define Tencent_RedirectURI  @"www.qq.com"

@interface ShareManager : NSObject 

@property UIViewController * rootVC;
@property (copy  ,nonatomic) ShareResultCallBack   callBack;

+(id)shareManager;
+(BOOL)handleOpenURL:(NSURL *)url;

/**
 * @brief  发起分享
 *
 * @param  share 分享内容ShareVO对象
 *
 * @return 返回发起是否成功.
 */
+(BOOL)shareWith:(ShareVO *)share;

/**
 * @brief  发起第三方登录
 *
 * @param  platform 第三方登录平台
 * @param  callBack 第三方登录回调
 *
 * @return 返回发起是否成功
 */
+(BOOL)logInWith:(PlatformType)platform and:(ShareResultCallBack)callBack;


/**
 * @brief  第三方取消绑定
 *
 * @param  platform 取消平台
 * @param  callBack 取消回调
 *
 * @return 返回取消是否成功
 */
+(BOOL)logOutWith:(PlatformType)platform and:(ShareResultCallBack)callBack;

/**
 * @brief  所有第三方取消绑定
 *
 * @param  callBack 取消回调
 *
 * @return 返回取消是否成功
 */
+(BOOL)logOutAllPlatform:(ShareResultCallBack)callBack;

@end
