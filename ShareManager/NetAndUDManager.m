//
//  ShareNetWork.m
//  ShareLxc
//
//  Created by Mr.S on 2016/12/20.
//  Copyright © 2016年 梁新昌. All rights reserved.
//

#import "NetAndUDManager.h"

@implementation NetAndUDManager

#pragma mark UD存储方法
+(void)saveObject:(NSString *)obj withKey:(NSString *)key
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud setObject:obj forKey:key];
    [ud synchronize];
}

+(NSString *)getObjectWithKey:(NSString *)key
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    return [ud objectForKey:key];
}

+(void)removeObjectWithKey:(NSString *)key
{
    NSUserDefaults* ud = [NSUserDefaults standardUserDefaults];
    [ud removeObjectForKey:key];
    [ud synchronize];
}

#pragma mark get请求
+(void)getWith:(NSString *)urlString completionHandler:(void (^)(NSDictionary * data,NSError *error))completionHandler
{
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        
        if (error == nil) {
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            completionHandler(dict,nil);
        }else
        {
            completionHandler(nil,error);
        }
    }];
    
    [dataTask resume];
}

@end
