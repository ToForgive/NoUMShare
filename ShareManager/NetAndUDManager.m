//
//  ShareNetWork.m
//  ShareLxc
//
//  Created by Mr.S on 2016/12/20.
//  Copyright © 2016年 梁新昌. All rights reserved.
//

#import "NetAndUDManager.h"
#import <objc/runtime.h>

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

+(NSDictionary*)getObjectData:(id)obj
{
    NSMutableDictionary*dic = [NSMutableDictionary dictionary];
    
    unsigned int propsCount;
    
    objc_property_t *props = class_copyPropertyList([obj class], &propsCount);
    
    for(int i = 0;i < propsCount; i++)
    {
        objc_property_t prop = props[i];
        
        NSString *propName = [NSString stringWithUTF8String:property_getName(prop)];
        
        id value = [obj valueForKey:propName];
        
        if(value == nil)
        {
            value = [NSNull null];
        }else
        {
            value = [self getObjectInternal:value];
            
        }
        
        [dic setObject:value forKey:propName];
        
    }
    return dic;
    
}

+(id)getObjectInternal:(id)obj
{
    if([obj isKindOfClass:[NSString class]] || [obj isKindOfClass:[NSNumber class]] || [obj isKindOfClass:[NSNull class]]){
        return obj;
    }
    
    if([obj isKindOfClass:[NSArray class]]){
        NSArray *objarr = obj;
        
        NSMutableArray *arr = [NSMutableArray arrayWithCapacity:objarr.count];
        
        for(int i = 0;i < objarr.count; i++) {
            [arr setObject:[self getObjectInternal:[objarr objectAtIndex:i]] atIndexedSubscript:i];
        }
        return arr;
    }
    
    if([obj isKindOfClass:[NSDictionary class]]){
        NSDictionary *objdic = obj;
        
        NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithCapacity:[objdic count]];
        
        for(NSString *key in objdic.allKeys)
        {
            [dic setObject:[self getObjectInternal:[objdic objectForKey:key]] forKey:key];
        }
        return dic;
        
    }
    return [self getObjectData:obj];
    
}

@end
