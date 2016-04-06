//
//  YYLoginViewController.m
//  XMPPTest2
//
//  Created by USER on 16/4/5.
//  Copyright © 2016年 Refresh_Yy. All rights reserved.
//

#import "YYLoginViewController.h"

#import "YYXMPPHelper.h"

#import "FriendListViewController.h"

@interface YYLoginViewController ()
@property (weak, nonatomic) IBOutlet UITextField *userNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *passwordTextField;

@end

@implementation YYLoginViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    NSLog(@"%@",[YYXMPPHelper shareInstance]);
}

- (void)viewWillAppear:(BOOL)animated
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    _userNameTextField.text = [userDefaults objectForKey:kUserJIDKey];
    
    _passwordTextField.text = [userDefaults objectForKey:kUserPasswordKey];
    
    
}


- (IBAction)loginClick:(UIButton *)sender {
    
    if (self.userNameTextField.text.length > 0 && self.passwordTextField.text.length > 0) {
        
        [[YYXMPPHelper shareInstance] loginWithJid:_userNameTextField.text password:_passwordTextField.text completion:^(BOOL isSuccessful, NSString *errorMsg) {
            
            if (isSuccessful) {
                
                [[NSUserDefaults standardUserDefaults] setObject:_userNameTextField.text forKey:kUserJIDKey];
                
                [[NSUserDefaults standardUserDefaults] setObject:_passwordTextField.text forKey:kUserPasswordKey];
                
                /*
                 在NSUserDefaults中，特别要注意的是苹果官方对于nsuserdefaults的描述，简单来说，当你按下home键后，NSUserDefaults是保存了的，但是当你在xcode中按下stop停止应用的运行时，NSUserDefaults是没有保存的，所以推荐使用[[NSUserDefaults standardUserDefaults] synchronize]来强制保存NSUserDefaults.
                 */
              
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                //登录后 跳转到好友列表页面
                FriendListViewController *vc = [[FriendListViewController alloc]init];
               
                [self.navigationController pushViewController:vc animated:YES];
                
            }else{
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:errorMsg delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil];
                
                [alert show];
            }
            
        }];
        
    }
    
}


- (IBAction)registerClick:(UIButton *)sender {
    
    
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
