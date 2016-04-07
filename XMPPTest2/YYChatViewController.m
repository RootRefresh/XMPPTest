
//
//  YYChatViewController.m
//  XMPPTest2
//
//  Created by USER on 16/4/7.
//  Copyright © 2016年 Refresh_Yy. All rights reserved.
//

#import "YYChatViewController.h"

#import "YYXMPPHelper.h"

#import "YYChatCell.h"

@interface YYChatViewController ()<UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>

@property (nonatomic,strong) UITableView        *tableView;

@property (nonatomic,strong) UITextField        *textField;

@property (nonatomic,strong) NSMutableArray     *dataArray;

@end

@implementation YYChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = self.friendJID;
    
    
    [self createTableView];
    [self createTextField];
    [self loadData];
    [self recieveNewMessage];
    
    
}

- (void)loadData
{
    self.dataArray = [NSMutableArray array];
}

- (void)createTextField
{
    self.textField                  = [[UITextField alloc]initWithFrame:CGRectMake(0, HEIGHT - 44, WIDTH, 44)];
    
    self.textField.backgroundColor  = [UIColor lightGrayColor];
    
    self.textField.delegate         = self;
    
    [self.view addSubview:self.textField];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardShow:(NSNotification *)noti
{
    //计算键盘高度
    float x = [[noti.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey]CGRectValue].size.height;
    
    [UIView animateWithDuration:0.3 animations:^{
        
        self.tableView.frame = CGRectMake(0, 0, WIDTH, HEIGHT - 64 - 44 - x);
        self.textField.frame = CGRectMake(0, HEIGHT - 44 - x, WIDTH, 44);
        
    }completion:^(BOOL finished) {
        
        //偏移
        if (self.dataArray.count) {
            [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
        }
        
        
    }];
    
}

- (void)keyboardHide:(NSNotification *)noti
{
    [UIView animateWithDuration:0.3 animations:^{
        
        self.tableView.frame = CGRectMake(0, 0, WIDTH, HEIGHT - 64 - 44);
        self.textField.frame = CGRectMake(0, HEIGHT - 44, WIDTH, 44);
        
    }];
}

#pragma mark textField 代理
- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.text.length > 0) {
        
        [[YYXMPPHelper shareInstance] sendText:textField.text toJid:self.friendJID completion:^(BOOL isSuccessful, NSString *errorMsg) {
            
            if (isSuccessful) {
                
                NSArray *array = @[textField.text,@"1"];
                [self.dataArray addObject:array];
                [self.tableView reloadData];
                
                //产生偏移
                [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
            }
            
        }];
        
        
        
        //1秒后自动回复
        // [self performSelector:@selector(autoBackMessage) withObject:nil afterDelay:1];
        
        
    }
    return YES;
}

- (void)autoBackMessage
{
    [self.dataArray addObject:@[@"自动回复",@"0"]];
    [self.tableView reloadData];
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

- (void)createTableView
{
    self.tableView = [[UITableView alloc]initWithFrame:CGRectMake(0, 0, WIDTH, HEIGHT - 64 - 44) style:UITableViewStylePlain];
    
    self.tableView.delegate         = self;
    self.tableView.dataSource       = self;
    
    self.tableView.separatorStyle   = UITableViewCellSeparatorStyleNone;
    
    [self.view addSubview:self.tableView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapClick)];
    [self.tableView addGestureRecognizer:tap];
}

- (void)tapClick
{
    [self.view endEditing:YES];
}

#pragma mark tableView 代理

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    YYChatCell *cell = [tableView dequeueReusableCellWithIdentifier:[YYChatCell description]];
    
    if (!cell) {
        
        cell = [[YYChatCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:[YYChatCell description]];
        
    }
    
    //读取数据源
    /*
     在设计数据源的时候，需要保存发送的文字和是不是自己发送的，所以在self.dataArray中每个元素是一个数组，数组中包含2个元素，一个是发送内容一个是不是自己
     */
    
    [cell configCell:self.dataArray[indexPath.row]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *string = [self.dataArray[indexPath.row] firstObject];
    
    CGSize size=[string boundingRectWithSize:CGSizeMake(200, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10]} context:nil].size;
    
    return size.height+30;
}


- (void)sendMessage:(NSString *)message toUser:(NSString *)user
{
    NSXMLElement *body = [NSXMLElement elementWithName:@"body"];
    [body setStringValue:message];
    
    NSXMLElement *message1 = [NSXMLElement elementWithName:@"message"];
    
    [message1 addAttributeWithName:@"type" stringValue:@"chat"];
    
    NSString *to = [NSString stringWithFormat:@"%@@127.0.0.1",user];
    
    [message1 addAttributeWithName:@"to" stringValue:to];
    
    [message1 addChild:body];
    
//    [_xmppStream sendElement:message1];
    
}

- (void)recieveNewMessage
{
    YYXMPPHelper *helper = [YYXMPPHelper shareInstance];
    
    helper.newMessageBlock = ^(NSString *message){
        
        [self.dataArray addObject:@[message,@"0"]];
        [self.tableView reloadData];
        [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:self.dataArray.count-1 inSection:0] atScrollPosition:UITableViewScrollPositionBottom animated:YES];
    };
    
//    [[YYXMPPHelper shareInstance] receiveNewMessageWithBlock:^(NSString *message) {
//        
//        
//        
//        
//    }];
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
