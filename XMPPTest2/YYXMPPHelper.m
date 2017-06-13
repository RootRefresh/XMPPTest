//
//  YYXMPPHelper.m
//  XMPPTest
//
//  Created by USER on 16/4/5.
//  Copyright © 2016年 Refresh_Yy. All rights reserved.
//

#import "YYXMPPHelper.h"

#import <XMPPReconnect.h>
#import <XMPPRosterCoreDataStorage.h>

#import <XMPPMessageArchiving.h>
#import <XMPPMessageArchivingCoreDataStorage.h>

#import <XMPPCapabilities.h>
#import <XMPPCapabilitiesCoreDataStorage.h>






#import "YYUserModel.h"

@interface YYXMPPHelper()
{
    NSString *_jid;
    NSString *_password;
    
    BOOL    _isRegister;
}

@property (nonatomic,strong) XMPPStream         *xmppStream;
@property (nonatomic,strong) XMPPReconnect      *xmppReconnect;

//花名册
@property (nonatomic,strong) XMPPRoster         *xmppRoster;
@property (nonatomic,strong) XMPPRosterCoreDataStorage *xmppRosterStorage;

//性能相关
@property (nonatomic,strong) XMPPCapabilities   *xmppCapabilities;
@property (nonatomic,strong) XMPPCapabilitiesCoreDataStorage *xmppCapabilitiesStorage;

// 消息相关
@property (nonatomic, strong) XMPPMessageArchiving *xmppMessageArchiving;
@property (nonatomic, strong) XMPPMessageArchivingCoreDataStorage *xmppMessageStorage;


@property (nonatomic, copy) YYCompletionBlock completionBlock;

@property (nonatomic, copy) YYFetchResultBlock friendListBlock;


@end


@implementation YYXMPPHelper

+ (YYXMPPHelper *)shareInstance
{
    static YYXMPPHelper     *instance;
    static dispatch_once_t  onceToken;
    
    dispatch_once(&onceToken, ^{
        
        instance = [[YYXMPPHelper alloc]init];
        
        [instance setUpXmppStream];
        
        [instance connect];
    });
    
    return instance;
}

- (void)setUpXmppStream
{
    NSAssert(_xmppStream == nil, @"-setupXmppStream method called multiple times");
    
    _jid = [[NSUserDefaults standardUserDefaults] objectForKey:kUserJIDKey];
    
    _password = [[NSUserDefaults standardUserDefaults] objectForKey:kUserPasswordKey];
    
    _xmppStream = [[XMPPStream alloc]init];

    [_xmppStream setHostName:kServer];
    
    [_xmppStream setHostPort:5222];
    
#if !TARGET_IPHONE_SIMULATOR
    // 设置此行为YES,表示允许socket在后台运行
    // 在模拟器上是不支持在后台运行的
  //  _xmppStream.enableBackgroundingOnSocket = YES;

#endif
    
    //XMPPReconnect 模块会监视 意外断开连接 并自动重连
    _xmppReconnect = [[XMPPReconnect alloc]init];
    
    _xmppRosterStorage = [[XMPPRosterCoreDataStorage alloc]init];
    
    _xmppRoster = [[XMPPRoster alloc]initWithRosterStorage:_xmppRosterStorage];

    //默认是 YES
    _xmppRoster.autoAcceptKnownPresenceSubscriptionRequests = YES;
    _xmppRoster.autoFetchRoster = YES;

    // 配置vCard存储支持，vCard模块结合vCardTempModule可下载用户Avatar
//    _xmppvCardStorage = [[XMPPvCardCoreDataStorage alloc] init];
//    _xmppvCardTempModule = [[XMPPvCardTempModule alloc] initWithvCardStorage:_xmppvCardStorage];
//    _xmppvCardAvatarModule = [[XMPPvCardAvatarModule alloc] initWithvCardTempModule:_xmppvCardTempModule];
//    
//    // XMPP特性模块配置，用于处理复杂的哈希协议等
//    _xmppCapailitiesStorage = [[XMPPCapabilitiesCoreDataStorage alloc] init];
//    _xmppCapabilities = [[XMPPCapabilities alloc] initWithCapabilitiesStorage:_xmppCapailitiesStorage];
//    _xmppCapabilities.autoFetchHashedCapabilities = YES;
//    _xmppCapabilities.autoFetchNonHashedCapabilities = NO;

    
    //为 XMPPStream 加装备
    [_xmppRoster    activate:_xmppStream];
    [_xmppReconnect activate:_xmppStream];
    
//    [_xmppvCardTempModule activate:_xmppStream];
//    [_xmppvCardAvatarModule activate:_xmppStream];
//    [_xmppCapabilities activate:_xmppStream];
    
    // 消息相关
//    _xmppMessageStorage = [[XMPPMessageArchivingCoreDataStorage alloc] init];
//    _xmppMessageArchiving = [[XMPPMessageArchiving alloc] initWithMessageArchivingStorage:_xmppMessageStorage];
//    [_xmppMessageArchiving setClientSideMessageArchivingOnly:YES];
//    [_xmppMessageArchiving activate:_xmppStream];

    // 添加代理
    [_xmppStream addDelegate:self delegateQueue:dispatch_get_main_queue()];
    [_xmppRoster addDelegate:self delegateQueue:dispatch_get_main_queue()];
    //[_xmppMessageArchiving addDelegate:self delegateQueue:dispatch_get_main_queue()];
    
}

- (BOOL)connect
{
    if (![_xmppStream isDisconnected]) {
        return YES;
    }
    
//    if (_jid == nil || _password == nil) {
//        return NO;
//    }
    

    if (_jid != nil) {
        
        [_xmppStream setMyJID:[XMPPJID jidWithString:_jid ]];
   
    }else{
    
        [_xmppStream setMyJID:[XMPPJID jidWithString:_xmppStream.hostName ]];
    }

    
    //连接服务器
    NSError *error = nil;
    
    if (![_xmppStream connectWithTimeout:XMPPStreamTimeoutNone error:&error]) {
        
        UIAlertView *alert = [[UIAlertView alloc]initWithTitle:@"连接失败"
                                                       message:@"在控制台看错误细节"
                                                      delegate:nil
                                             cancelButtonTitle:@"OK"
                                             otherButtonTitles: nil];
        [alert show];
        
        NSLog(@"连接错误原因: %@",[error description]);
        
        return NO;
    }else{
        
        NSLog(@"服务器连接成功");
    
    }
    
    return YES;
}

- (void)goOnline
{
    // 获取现场节点，默认type = "available"

    XMPPPresence *presence = [XMPPPresence presence];
    
    NSString *domain = [_xmppStream.myJID domain];
    
    if ([domain isEqualToString:@"gmail.com"]||[domain isEqualToString:@"gtalk.com"]||[domain isEqualToString:@"talk.google.com"]) {
        
        NSXMLElement *priority = [NSXMLElement elementWithName:@"priority" stringValue:@"24"];
        
        [presence addChild:priority];
    }
    
    [_xmppStream sendElement:presence];
    
}

- (void)goOffline
{
    XMPPPresence *presence = [XMPPPresence presenceWithType:@"unavailable"];
    [_xmppStream sendElement:presence];

}

#pragma mark ### 注册 ###
- (void)registerWithJid:(NSString *)jidString password:(NSString *)password completion:(YYCompletionBlock)completion
{
    if (jidString == nil ||password == nil) {
        if (completion) {
            completion(NO,@"用户名密码不能为空");
        }
        return;
    }
    
    if ([_xmppStream isDisconnected]) {
        
        if (![self connect]) {
            
            if (completion) {
                completion(NO,@"服务器连接失败");
            }
            
        }
        return;
    }
    
    _password = password;
    
    
    
}

- (void)registerWithJid:(NSString *)jidString
{
    if (![jidString hasSuffix:kServer]) {
        
        jidString = [NSString stringWithFormat:@"%@@%@",jidString,kServer];
        
    }
    
    [_xmppStream setMyJID:[XMPPJID jidWithString:jidString]];
    
    NSError *error;
    
    if (![_xmppStream registerWithPassword:_password error:&error]) {
        
        NSLog(@"注册账号失败，原因：%@", [error description]);
        
        if (self.completionBlock) {
            
            self.completionBlock(NO, [error description]);
            
        }
    }
}

#pragma mark ### 登录 ###
- (void)loginWithJid:(NSString *)jidString password:(NSString *)password completion:(YYCompletionBlock)completion
{
    if (_xmppStream.isAuthenticated) {
        
        if (completion) {
           
            completion(YES, nil);
        }
        
        return;
    }
    
    if (jidString == nil || password == nil) {
      
        if (completion) {
            completion(NO,@"用户名或密码不能为空");
        }
        return;
    }
    
    if ([_xmppStream isDisconnected]) {
        
        if (![self connect]) {
            
            if (completion) {
                
                completion(NO,@"服务器连接失败");
             
                return;
            }
        }
    }
    
    if (![jidString hasSuffix:kServer]) {
        
        jidString = [NSString stringWithFormat:@"%@@%@",jidString,kServer];
        
    }
    
    [_xmppStream setMyJID:[XMPPJID jidWithString:jidString]];
    
    NSError *error;
    
    if ([_xmppStream authenticateWithPassword:password error:&error]) {
        
        NSLog(@"登录成功");
        
        if (completion) {
            completion(YES, nil);
        }
        
    }else{
        
        NSLog(@"登录失败：%@",[error description]);
        
        if (completion) {
            completion(NO, [error description]);
        }
    }
}

//- (BOOL)loginWithJid:(NSString *)jidString
//{
//    if (![jidString hasSuffix:kServer]) {
//        
//        jidString = [NSString stringWithFormat:@"%@@%@",jidString,kServer];
//        
//    }
//    
//    [_xmppStream setMyJID:[XMPPJID jidWithString:jidString]];
//    
//    NSError *error;
//    
//    if ([_xmppStream authenticateWithPassword:_password error:&error]) {
//        
//        NSLog(@"登录成功");
//
////        if (self.completionBlock) {
////            self.completionBlock(YES, nil);
////        }
//        
//        return YES;
//        
//    }else{
//       
//        NSLog(@"登录失败：%@",[error description]);
//        
////        if (self.completionBlock) {
////            
////            self.completionBlock(NO,[error description]);
////            
////        }
//        return NO;
//    }
//}


#pragma mark ### 请求好友列表 ###
/*
 一个 IQ 请求：
 <iq type="get"
 　　from="xiaoming@example.com"
 　　to="example.com"
 　　id="1234567">
 　　<query xmlns="jabber:iq:roster"/>
 <iq />
 
 type 属性，说明了该 iq 的类型为 get，与 HTTP 类似，向服务器端请求信息
 from 属性，消息来源，这里是你的 JID
 to 属性，消息目标，这里是服务器域名
 id 属性，标记该请求 ID，当服务器处理完毕请求 get 类型的 iq 后，响应的 result 类型 iq 的 ID 与 请求 iq 的 ID 相同
 <query xmlns="jabber:iq:roster"/> 子标签，说明了客户端需要查询 roster
 */
#pragma mark - Private
- (NSManagedObjectContext *)rosterContext {
    return [_xmppRosterStorage mainThreadManagedObjectContext];
}

- (void)fetchFriendListWithCompletion:(YYFetchResultBlock)completion
{
    self.friendListBlock = completion;
    
    // 通过coredata 获取好友列表 很牛Bility的 便捷方式
    NSManagedObjectContext *context = [self rosterContext];
    
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"XMPPUserCoreDataStorageObject" inManagedObjectContext:context];
    
    NSFetchRequest *request = [[NSFetchRequest alloc]init];
    [request setEntity:entity];
    
    __block NSError *error = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        NSArray *results = [context executeFetchRequest:request error:&error];
        
        dispatch_async(dispatch_get_main_queue(), ^{
           
            if (completion) {
                completion(results, [error description]);
            }
            
        });
        
    });
    // 下面的方法是从服务器中查询获取好友列表
      // 创建iq节点
//      NSXMLElement *iq = [NSXMLElement elementWithName:@"iq"];
//      [iq addAttributeWithName:@"type" stringValue:@"get"];
//      [iq addAttributeWithName:@"from" stringValue:[NSString stringWithFormat:@"%@@%@", _jid, kServer]];
//      [iq addAttributeWithName:@"to" stringValue:kServer];
//      [iq addAttributeWithName:@"id" stringValue:@"123"];
//      // 添加查询类型
//      NSXMLElement *query = [NSXMLElement elementWithName:@"query" xmlns:@"jabber:iq:roster"];
//      [iq addChild:query];
//    
//      // 发送查询
//      [_xmppStream sendElement:iq];
}


#pragma  mark  ### XMPPStreamDelegate 连接部分

- (void)xmppStreamWillConnect:(XMPPStream *)sender
{
    NSLog(@"xmpp stream 即将连接");
}

- (void)xmppStreamDidConnect:(XMPPStream *)sender
{
    NSLog(@"xmpp stream 已经连接");
    
    //NSString *password = [[NSUserDefaults standardUserDefaults] objectForKey:kUserPasswordKey];
//    NSError *error;
// 
//    if (![_xmppStream authenticateWithPassword:password error:&error]) {
//        
//        NSLog(@"密码校验失败，登录不成功");
//
//    }
}

- (void)xmppStreamConnectDidTimeout:(XMPPStream *)sender
{
    NSLog(@"xmpp stream 连接超时");
}

- (void)xmppStream:(XMPPStream *)sender socketDidConnect:(GCDAsyncSocket *)socket
{
    NSLog(@"socketDidConnect 已经连接");
}

#pragma mark 登录相关
// @begin
- (void)xmppStreamDidAuthenticate:(XMPPStream *)sender
{
    NSLog(@"密码校验成功，用户将要上线");
    
    [self goOnline];
}

- (void)xmppStream:(XMPPStream *)sender didNotAuthenticate:(DDXMLElement *)error
{
    NSLog(@"密码验证失败 原因：%@",[error XMLString]);
}

// @end

- (void)xmppStream:(XMPPStream *)sender didReceiveError:(id)error {
    NSLog(@"接收信息时，出现异常：%@", [error description]);
}

- (void)xmppStreamDidDisconnect:(XMPPStream *)sender withError:(NSError *)error {
    NSLog(@"xmpp stream 退出连接失败：%@", [error description]);
}

- (XMPPIQ *)xmppStream:(XMPPStream *)sender willReceiveIQ:(XMPPIQ *)iq {
    NSLog(@"willReceiveIQ: %@", iq.type);
    
    return iq;
}

/*
 一个 IQ 响应：
 <iq type="result"
 　　id="1234567"
 　　to="xiaoming@example.com">
 　　<query xmlns="jabber:iq:roster">
 　　　　<item jid="xiaoyan@example.com" name="小燕" />
 　　　　<item jid="xiaoqiang@example.com" name="小强"/>
 　　<query />
 <iq />
 type 属性，说明了该 iq 的类型为 result，查询的结果
 <query xmlns="jabber:iq:roster"/> 标签的子标签 <item />，为查询的子项，即为 roster
 item 标签的属性，包含好友的 JID，和其它可选的属性，例如昵称等。
 */

- (BOOL)xmppStream:(XMPPStream *)sender didReceiveIQ:(XMPPIQ *)iq
{
    if ([@"result" isEqualToString:iq.type]) {
        
        NSXMLElement *query = iq.childElement;
        
        if ([iq attributeStringValueForName:@"from"] && [iq attributeStringValueForName:@"to"]) {
            
            return YES;
        }
        
        //用户不存在
        
        if (query == nil) {
            return YES;
        }
        // 这种方式是通过手动发送IQ来查询好友列表的，不过这样操作不如使用XMPP自带的coredata操作方便
            NSString *thdID = [NSString stringWithFormat:@"%@", [iq attributeStringValueForName:@"id"] ];
            if ([thdID isEqualToString:@"123"]) {
              NSXMLElement *query = [iq elementForName:@"query"];
        
              NSMutableArray *result = [[NSMutableArray alloc] init];
              for (NSXMLElement *item in query.children) {
                NSString *jid = [item attributeStringValueForName:@"jid"];
                NSString *name = [item attributeStringValueForName:@"name"];
        
                YYUserModel *model = [[YYUserModel alloc] init];
                model.jid = jid;
                model.name = name;
        
                [result addObject:model];
              }
                NSLog(@"%@",result);
                
              if (self.friendListBlock) {
                self.friendListBlock(result, nil);
              }
              
              return YES;
            }
    }else if ([iq.type isEqualToString:@"set"]){
        
        NSXMLElement *query = [iq elementForName:@"query"];
       
        for (NSXMLElement *item in query.children) {
        
            NSString *ask = [item attributeStringValueForName:@"ask"];
            
            NSString *subscription = [item attributeStringValueForName:@"subscription"];
            
            if ([ask isEqualToString:@"unsubscribe"] && ![subscription isEqualToString:@"none"]) {
                
                // 删除好友成功
//                if (self.completionBlock) {
//                    self.completionBlock(YES, nil);
//                }
                return YES;
            
            }
            // 请求添加好友，但是查询没有结果，表示用户不存在
            // none表示未确认
            else if([ask isEqualToString:@"subscribe"] && [subscription isEqualToString:@"none"]){
                
                
                NSLog(@"发送添加好友请求成功");
                
                return YES;

            }else if (![subscription isEqualToString:@"none"]) { // 添加好友请求，查询成功
                return YES;
            }
            
        }
    
    
    }
    
    return NO;
}

- (void)xmppStream:(XMPPStream *)sender didReceiveMessage:(XMPPMessage *)message
{
    NSLog(@"xmpp stream 接收到好友消息：%@", [message XMLString]);
    
    NSString *messageBody = [[message elementForName:@"body"] stringValue];
    
    //self.newMessageBlock = ^(NSString *string){};
    
    if (nil != messageBody) {
        
        if (self.newMessageBlock) {
            self.newMessageBlock(messageBody);
        }
        
    }

}

- (void)receiveNewMessageWithBlock:(YYGetNewMessageBlock)block
{
    self.newMessageBlock = block;
}

#pragma mark 注册代理
// @begin
- (void)xmppStreamDidRegister:(XMPPStream *)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:sender.myJID.user forKey:kUserJIDKey];
    
    NSLog(@"注册成功");
}


- (void)xmppStream:(XMPPStream *)sender didNotRegister:(DDXMLElement *)error
{
    NSLog(@"账户注册失败 %@",error);
}

// @end

/*
 presence.type有以下几种状态：
 
 available: 表示处于在线状态(通知好友在线)
 unavailable: 表示处于离线状态（通知好友下线）
 subscribe: 表示发出添加好友的申请（添加好友请求）
 unsubscribe: 表示发出删除好友的申请（删除好友请求）
 unsubscribed: 表示拒绝添加对方为好友（拒绝添加对方为好友）
 error: 表示presence信息报中包含了一个错误消息。（出错）
 */
- (void)xmppStream:(XMPPStream *)sender didReceivePresence:(XMPPPresence *)presence {
    NSLog(@"接收到好友申请消息：%@", [presence fromStr]);
    // 好友在线状态
    NSString *type = [presence type];
    // 发送请求者
    NSString *fromUser = [[presence from] user];
    NSLog(@"接收到好友请求状态：%@   发送者：%@", type, fromUser);
    
    // 好友上线下线处理，具体应该要在此做一些处理，如更新好友在线状态
    // TO DO
    
    NSString *stateString;
    
    if ([type isEqualToString:@"available"]) {
        
        stateString = @"在线";
        
    }else if ([type isEqualToString:@"unavailable"]){
        
        stateString = @"离线";

    }
    
    if (self.newPresenceBlock) {
        
        self.newPresenceBlock(fromUser,stateString);
        
    }
}

- (void)xmppStream:(XMPPStream *)sender didSendMessage:(XMPPMessage *)message {
//    if (self.sendMessageBlock) {
//        self.sendMessageBlock(YES, nil);
//    }
}

- (void)xmppStream:(XMPPStream *)sender didFailToSendMessage:(XMPPMessage *)message error:(NSError *)error {
//    if (self.sendMessageBlock) {
//        self.sendMessageBlock(NO, [error description]);
//    }
}


#pragma mark ### 添加好友 ###

- (void)addFriendWithJid:(NSString *)jidString completion:(YYCompletionBlock)completion
{
    if (![jidString hasSuffix:kServer]) {
        
        jidString = [NSString stringWithFormat:@"%@@%@",jidString,kServer];
        
    }
    
    //先判断是否已经是好友
    
    if ([_xmppRosterStorage userForJID:[XMPPJID jidWithString:jidString] xmppStream:_xmppStream managedObjectContext:[self rosterContext]]) {
        
        if (completion) {
            completion(NO,[NSString stringWithFormat:@"%@已经是好友",jidString]);
        }
        
        return;
    }
    
    self.completionBlock = completion;
    
    [_xmppRoster subscribePresenceToUser:[XMPPJID jidWithString:jidString]];
    if (completion) {
        completion(YES, nil);
    }
}

- (void)removeFriendWithJid:(NSString *)jidString completion:(YYCompletionBlock)completion
{
    if (![jidString hasSuffix:kServer]) {
        
        jidString = [NSString stringWithFormat:@"%@@%@",jidString,kServer];
        
    }
    
    self.completionBlock = completion;
    
    [_xmppRoster removeUser:[XMPPJID jidWithString:jidString]];
    
    if(completion){
        completion(YES,nil);
    }
}

/*
 presence.type有以下几种状态：
 
 available: 表示处于在线状态(通知好友在线)
 unavailable: 表示处于离线状态（通知好友下线）
 subscribe: 表示发出添加好友的申请（添加好友请求）
 unsubscribe: 表示发出删除好友的申请（删除好友请求）
 unsubscribed: 表示拒绝添加对方为好友（拒绝添加对方为好友）
 error: 表示presence信息报中包含了一个错误消息。（出错）
 */
#pragma mark ### 花名册相关 ###
- (void)xmppRoster:(XMPPRoster *)sender didReceivePresenceSubscriptionRequest:(XMPPPresence *)presence {
    NSLog(@"接收到好友申请消息：%@", [presence fromStr]);
    // 好友在线状态
    NSString *type = [presence type];
    // 发送请求者
    NSString *fromUser = [[presence from] user];
    // 接收者id
    NSString *user = _xmppStream.myJID.user;
    
    NSLog(@"接收到好友请求状态：%@   发送者：%@  接收者：%@", type, fromUser, user);
    
    // 防止自己添加自己为好友
    if (![fromUser isEqualToString:user]) {
        if ([type isEqualToString:@"subscribe"]) { // 添加好友
            // 接受添加好友请求,发送type=@"subscribed"表示已经同意添加好友请求并添加到好友花名册中
            [_xmppRoster acceptPresenceSubscriptionRequestFrom:[XMPPJID jidWithString:fromUser]
                                                andAddToRoster:YES];
            NSLog(@"已经添加对方为好友，这里就没有弹出让用户选择是否同意，自动同意了");
        } else if ([type isEqualToString:@"unsubscribe"]) { // 请求删除好友
            
        }
    }
}

// 添加好友同意后，会进入到此代理
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterPush:(XMPPIQ *)iq {
    NSLog(@"花名册操作成功!!!didReceiveRosterPush -> :%@",iq.description);
    
    DDXMLElement *query = [iq elementsForName:@"query"][0];
    DDXMLElement *item = [query elementsForName:@"item"][0];
    
    NSString *subscription = [[item attributeForName:@"subscription"] stringValue];
    // 对方请求添加我为好友且我已同意
    if ([subscription isEqualToString:@"from"]) {// 对方关注我
        NSLog(@"我已同意对方添加我为好友的请求");
    }
    // 我成功添加对方为好友
    else if ([subscription isEqualToString:@"to"]) {// 我关注对方
        NSLog(@"我成功添加对方为好友，即对方已经同意我添加好友的请求");
    } else if ([subscription isEqualToString:@"remove"]) {
         //删除好友
        if (self.completionBlock) {
            self.completionBlock(YES, nil);
        }
    }
    
    if (self.friendListBlock) {
        // 更新好友列表
        [self fetchFriendListWithCompletion:self.friendListBlock];
    }
}

/**
 * Sent when the roster receives a roster item.
 *
 * Example:
 *
 * <item jid='romeo@example.net' name='Romeo' subscription='both'>
 *   <group>Friends</group>
 * </item>
 **/
// 已经互为好友以后，会回调此
- (void)xmppRoster:(XMPPRoster *)sender didReceiveRosterItem:(NSXMLElement *)item {
    NSString *subscription = [item attributeStringValueForName:@"subscription"];
    if ([subscription isEqualToString:@"both"]) {
        NSLog(@"双方已经互为好友");
        if (self.friendListBlock) {
            // 更新好友列表
            [self fetchFriendListWithCompletion:self.friendListBlock];
        }
    }
}

- (void)sendText:(NSString *)text toJid:(NSString *)jidString completion:(YYCompletionBlock)completion
{
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:text];
    
    NSXMLElement *message = [NSXMLElement elementWithName:@"message"];
    [message addAttributeWithName:@"type" stringValue:@"chat"];
    
    if (![jidString hasSuffix:kServer]) {
        jidString = [NSString stringWithFormat:@"%@@%@", jidString, kServer];
    }
    
    [message addAttributeWithName:@"to" stringValue:jidString];
    
    [message addChild:body];
    
    [_xmppStream sendElement:message];
    
    if (completion) {
        completion(YES,nil);
    }
    
}

@end
