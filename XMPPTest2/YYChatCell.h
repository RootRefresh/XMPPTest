//
//  YYChatCell.h
//  XMPPTest2
//
//  Created by USER on 16/4/7.
//  Copyright © 2016年 Refresh_Yy. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YYChatCell : UITableViewCell

@property (nonatomic,strong) UIImageView    *friendIcon;
@property (nonatomic,strong) UIImageView    *myIcon;

@property (nonatomic,strong) UIImageView    *friendBubble;
@property (nonatomic,strong) UIImageView    *myBubble;

@property (nonatomic,strong) UILabel        *friendLabel;
@property (nonatomic,strong) UILabel        *myLabel;

- (void)configCell:(NSArray *)dataArray;


@end
