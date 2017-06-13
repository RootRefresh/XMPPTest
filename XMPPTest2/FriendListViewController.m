//
//  FriendListViewController.m
//  XMPPTest2
//
//  Created by USER on 16/4/6.
//  Copyright © 2016年 Refresh_Yy. All rights reserved.
//

#import "FriendListViewController.h"

#import "YYXMPPHelper.h"
#import <XMPPUserCoreDataStorageObject.h>
#import "YYChatViewController.h"


@interface FriendListViewController ()<UITableViewDataSource,UITableViewDelegate,UIAlertViewDelegate>

@property (nonatomic,strong) NSMutableArray *friendArray;

@property (nonatomic,strong) UITableView *tableView;


@end

@implementation FriendListViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self createTableView];
    
    [self setNavigationBar];
    self.view.backgroundColor = [UIColor whiteColor];
    self.friendArray = [NSMutableArray array];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (_friendArray.count == 0) {
        
        [self loadFriendList];
        
    }
}

- (void)loadFriendList
{
    static int count = 0;
    
    [[YYXMPPHelper shareInstance] fetchFriendListWithCompletion:^(NSArray *friendList, NSString *errorMsg) {
       
        if (friendList && friendList.count) {
            
           dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            
                [self.friendArray removeAllObjects];
                
                [self.friendArray addObjectsFromArray:friendList];

               dispatch_async(dispatch_get_main_queue(), ^{
                    
                    [self.tableView reloadData];
                    
                    count = 0;
                    
                });
               
            });
            
        }else{
            
            count ++;
            
            if (self.friendArray.count == 0 && count <= 10) {
                
                [self performSelector:@selector(loadFriendList) withObject:nil afterDelay:0.5];
                
                
            }
        }
        
        
    }];
    
    
}

- (void)setNavigationBar
{
    UIBarButtonItem *rightItem = [[UIBarButtonItem alloc]initWithTitle:@"添加好友" style:UIBarButtonItemStylePlain target:self action:@selector(rightBarButtonClick)];
   // UIBarButtonItem *leftItem = [[UIBarButtonItem alloc]initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(leftBarButtonClick)];
    
    self.navigationItem.rightBarButtonItem = rightItem;
  //  self.navigationItem.leftBarButtonItem  = leftItem;
}

- (void)rightBarButtonClick
{
    UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:@"" message:@"请输入好友名" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"添加", nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
    
    [self.view addSubview:alertView];
    
    [alertView show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) {
        
        UITextField  *textField = [alertView textFieldAtIndex:0];
        
        [[YYXMPPHelper shareInstance] addFriendWithJid:textField.text completion:^(BOOL isSuccessful, NSString *errorMsg) {
            
            if (isSuccessful) {
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:@"添加好友成功" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                
                [alert show];
                
                
                
            }else{
              
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alert show];
            }
            
            
        }];
        
    }
}


- (void)createTableView
{
    self.tableView              = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT) style:UITableViewStylePlain];
    
    self.tableView.delegate     = self;
    
    self.tableView.dataSource   = self;
    
    [self.view addSubview:self.tableView];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSLog(@"friendArray :%ld",self.friendArray.count);
    
    return self.friendArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ID"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"ID"];
    }
    
    /*
     subscription:
     .如果是none表示对方还没有确认
     .to 我关注对方
     . from 对方关注我
     .both 互粉
     
     section:
     .0 在线
     .1 离开
     .2 离线
     
     */
    
    if (self.friendArray.count > indexPath.row) {
        
        XMPPUserCoreDataStorageObject *model = self.friendArray[indexPath.row];
       
        cell.textLabel.text = [NSString stringWithFormat:@"%@  |  %@",
                               [[model.jidStr componentsSeparatedByString:@"@"] firstObject],[self subscriptionText:model.subscription]];
        
        cell.detailTextLabel.text = model.section ==0 ? @"在线" : model.section == 1 ? @"离开" :@"离线";
    }
    
    
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
         XMPPUserCoreDataStorageObject *model = [self.friendArray objectAtIndex:indexPath.row];
        
        [[YYXMPPHelper shareInstance] removeFriendWithJid:model.jidStr completion:^(BOOL isSuccessful, NSString *errorMsg) {
            
            if (isSuccessful) {
                
                [self.friendArray removeObject:model];
                
                [tableView reloadData];
                
                //单一删除 行会出错 待研究 和helper中的 两个block有关
//                NSLog(@"删除之前 %ld",self.friendArray.count);
//                
//                [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
                
            }else{
               
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                [alert show];
                
            }
            
            
        }];
        
        
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    XMPPUserCoreDataStorageObject *modle = self.friendArray[indexPath.row];
    
    YYChatViewController *vc = [[YYChatViewController alloc]init];
    
    vc.friendJID             = [[modle.jidStr componentsSeparatedByString:@"@"] firstObject];
    
    [self.navigationController pushViewController:vc animated:YES];
    
}


- (NSString *)subscriptionText:(NSString *)subscription {
    if ([subscription isEqualToString:@"to"]) {
        return @"我关注对方";
    } else if ([subscription isEqualToString:@"from"]) {
        return @"对方关注我";
    } else if ([subscription isEqualToString:@"both"]) {
        return @"互为好友";
    }
    
    return @"对方还没有确认";
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
