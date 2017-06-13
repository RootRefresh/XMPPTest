//
//  YYChatCell.m
//  XMPPTest2
//
//  Created by USER on 16/4/7.
//  Copyright © 2016年 Refresh_Yy. All rights reserved.
//

#import "YYChatCell.h"

#define WIDTH   [UIScreen mainScreen].bounds.size.width
#define HEIGHT  [UIScreen mainScreen].bounds.size.height

@implementation YYChatCell
- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        
        [self makeUI];
        
    }
    
    return self;
}

- (void)makeUI
{
    self.friendIcon                     = [[UIImageView alloc]initWithFrame:CGRectMake(5, 5, 40, 40)];
    
    self.friendIcon.layer.cornerRadius  = 20;
    
    self.friendIcon.layer.masksToBounds = YES;
    
    self.friendIcon.image               = [UIImage imageNamed:@"1.jpg"];
    
    [self.contentView addSubview:self.friendIcon];
    
    self.myIcon                         = [[UIImageView alloc]initWithFrame:CGRectMake(WIDTH - 50, 5, 40, 40)];
    
    self.myIcon.layer.cornerRadius      = 20;
    
    self.myIcon.layer.masksToBounds     = YES;
    
    self.myIcon.image                   = [UIImage imageNamed:@"2.jpg"];
    
    [self.contentView addSubview:self.myIcon];
    
    self.friendBubble                   = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 100, 20)];
    
    UIImage *image                      = [UIImage imageNamed:@"fcl_chat_me.png"];
    
    image                               = [UIImage imageWithCGImage:image.CGImage scale:2 orientation:UIImageOrientationUpMirrored];
    
    image                               = [image stretchableImageWithLeftCapWidth:23 topCapHeight:10];
    
    self.friendBubble.image             = image;
    
    [self.contentView addSubview:self.friendBubble];
    
    self.myBubble                       = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, 100, 20)];
    
    UIImage *image1                     = [UIImage imageNamed:@"fcl_chat_me.png"];
    
    image1                              = [image1 stretchableImageWithLeftCapWidth:23 topCapHeight:10];
    
    self.myBubble.image                 = image1;
    
    [self.contentView addSubview:self.myBubble];
    
    self.friendLabel                    = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 20)];
    self.friendLabel.numberOfLines      = 0;
    self.friendLabel.font               = [UIFont systemFontOfSize:10];
    [self.friendBubble addSubview:self.friendLabel];
    
    self.myLabel                        = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, 100, 20)];
    self.myLabel.numberOfLines          = 0;
    self.myLabel.font                   = [UIFont systemFontOfSize:10];
    [self.myBubble addSubview:self.myLabel];
}

- (void)configCell:(NSArray *)dataArray
{
    NSString *string    = [dataArray firstObject];
    CGSize size         = [string boundingRectWithSize:CGSizeMake(200, 1000) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:10]} context:nil].size;
    
    if ([[dataArray lastObject] intValue] == 0) {
        
        //好友
        
        self.myIcon.hidden      = YES;
        self.myBubble.hidden    = YES;
        
        self.friendIcon.hidden  = NO;
        self.friendBubble.hidden= NO;
        
        self.friendBubble.frame = CGRectMake(50, 5, size.width+20, size.height+20);
        self.friendLabel.frame  = CGRectMake(10, 10, size.width, size.height);
        self.friendLabel.text   = string;
        
    }else{
        
        //自己
        
        self.myIcon.hidden      = NO;
        self.myBubble.hidden    = NO;
        
        self.friendIcon.hidden  = YES;
        self.friendBubble.hidden= YES;
        
        self.myBubble.frame     = CGRectMake(WIDTH - 50 - size.width - 20, 5, size.width+20, size.height+20);
        self.myLabel.frame      = CGRectMake(10, 10, size.width, size.height);
        self.myLabel.text       = string;
    }
}

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
