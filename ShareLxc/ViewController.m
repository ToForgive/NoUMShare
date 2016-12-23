//
//  ViewController.m
//  ShareLxc
//
//  Created by 梁新昌 on 2016/12/19.
//  Copyright © 2016年 梁新昌. All rights reserved.
//

#import "ViewController.h"
#import "ShareManager.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet UISegmentedControl *segment;
@property (weak, nonatomic) IBOutlet UIButton *shareButton;
@property (weak, nonatomic) IBOutlet UIButton *logoutButton;
@property (weak, nonatomic) IBOutlet UIButton *loginButton;
@property (weak, nonatomic) IBOutlet UIButton *allLogoutButton;

@end

@implementation ViewController

//分享
- (IBAction)shareButtonPressed:(UIButton *)sender {
    //创建分享实例对象
    ShareVO *shareVO = [[ShareVO alloc] init];
    shareVO.platform = self.segment.selectedSegmentIndex;
    shareVO.title = @"lalalalala";
    shareVO.des = @"这是一个超越 UM 的封装";
    shareVO.image = @"https://img0.bdstatic.com/static/searchdetail/img/logo-2X_b99594a.png";
    shareVO.link = @"https://www.baidu.com";
    shareVO.rootVC = self;
    //设置分享回调函数 ⚠️ 这个必须有
    [shareVO shareComplate:^(NSString *message, AuthorizeVO *userInfo) {
        if (message) {
            NSLog(@"%@",message);
        }else
        {
            NSLog(@"分享成功");
        }
    }];
    [ShareManager shareWith:shareVO];
}
//登录
- (IBAction)login:(UIButton *)sender {
    [ShareManager logInWith:self.segment.selectedSegmentIndex and:^(NSString *message, AuthorizeVO *userInfo) {
        if (message) {
            NSLog(@"%@",message);
        }else
        {
            NSLog(@"%@",userInfo);
        }
    }];
}
//登出
- (IBAction)logout:(UIButton *)sender {
    [ShareManager logOutWith:self.segment.selectedSegmentIndex and:^(NSString *message, AuthorizeVO *userInfo) {
        if (message) {
            NSLog(@"%@",message);
        }else
        {
            NSLog(@"已退出  %ld",(long)self.segment.selectedSegmentIndex);
        }
    }];
}
//全部登出
- (IBAction)logoutAll:(UIButton *)sender {
    [ShareManager logOutAllPlatform:^(NSString *message, AuthorizeVO *userInfo) {
        if (message) {
            NSLog(@"%@",message);
        }else
        {
            NSLog(@"已全部退出");
        }
    }];
}

@end
