//
//  ShareNetWork.h
//  ShareLxc
//
//  Created by Mr.S on 2016/12/20.
//  Copyright © 2016年 梁新昌. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ShareNetWork : NSObject

+(void)saveObject:(NSString *)obj withKey:(NSString *)key;
+(NSString *)getObjectWithKey:(NSString *)key;
+(void)removeObjectWithKey:(NSString *)key;

+(void)getWith:(NSString *)urlString completionHandler:(void (^)(NSDictionary * data,NSError *error))completionHandler;

@end
