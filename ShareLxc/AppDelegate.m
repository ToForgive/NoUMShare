//
//  AppDelegate.m
//  ShareLxc
//
//  Created by 梁新昌 on 2016/12/19.
//  Copyright © 2016年 梁新昌. All rights reserved.
//

#import "AppDelegate.h"
#import "ShareManager.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [ShareManager shareManager];
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [ShareManager handleOpenURL:url];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    return [ShareManager handleOpenURL:url];
}

@end
