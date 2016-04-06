//
//  YYXMPPHelper.h
//  XMPPTest
//
//  Created by USER on 16/4/5.
//  Copyright © 2016年 Refresh_Yy. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <XMPPFramework.h>
#import <XMPPRoster.h>

#define kServer             @"127.0.0.1"
#define kUserJIDKey         @"kUserJIDStringKey"
#define kUserPasswordKey    @"KUserPasswordKey"

#define WIDTH               self.view.frame.size.width
#define HEIGHT              self.view.frame.size.height


typedef void (^YYCompletionBlock)(BOOL isSuccessful,NSString *errorMsg);

typedef void(^YYFetchResultBlock)(NSArray *friendList,NSString *errorMsg);

@interface YYXMPPHelper : NSObject <XMPPStreamDelegate,XMPPRosterDelegate>



+ (YYXMPPHelper *)shareInstance;

- (BOOL)connect;

//上线
- (void)goOnline;

//下线
- (void)goOffline;

//注册
- (void)registerWithJid:(NSString *)jidString
               password:(NSString *)password
             completion:(YYCompletionBlock)completion;

//登录
- (void)loginWithJid:(NSString *)jidString
            password:(NSString *)password
          completion:(YYCompletionBlock)completion;

//添加好友
- (void)addFriendWithJid:(NSString *)jidString
              completion:(YYCompletionBlock)completion;

//删除好友
- (void)removeFriendWithJid:(NSString *)jidString
                 completion:(YYCompletionBlock)completion;


//获取好友列表
- (void)fetchFriendListWithCompletion:(YYFetchResultBlock)completion;



@end
