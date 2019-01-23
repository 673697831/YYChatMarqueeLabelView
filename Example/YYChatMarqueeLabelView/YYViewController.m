//
//  YYViewController.m
//  YYChatMarqueeLabelView
//
//  Created by 673697831 on 01/23/2019.
//  Copyright (c) 2019 673697831. All rights reserved.
//

#import "YYViewController.h"
#import "YYChatMarqueeLabelView.h"

@interface YYViewController ()

@end

@implementation YYViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"123467889" attributes:@
                                      {
                                      NSFontAttributeName:[UIFont systemFontOfSize:16],
                                      NSForegroundColorAttributeName:[UIColor greenColor],
                                      }];
    NSTextAttachment *imageAttachment = [NSTextAttachment new];
    UIImage * image = [UIImage imageNamed:@"ActivityIcon"];
    imageAttachment.image = image;
    imageAttachment.bounds = CGRectMake(0, 0, imageAttachment.image.size.width, imageAttachment.image.size.height);
    NSAttributedString *str1 = [NSAttributedString attributedStringWithAttachment:imageAttachment];
    NSAttributedString *str2 = [[NSAttributedString alloc] initWithString:@"123456789" attributes:@
                                {
                                NSFontAttributeName:[UIFont systemFontOfSize:20],
                                NSForegroundColorAttributeName:[UIColor redColor],
                                }];
    NSAttributedString *str3 = [NSAttributedString attributedStringWithAttachment:imageAttachment];
    [str appendAttributedString:str1];
    [str appendAttributedString:str2];
    [str appendAttributedString:str3];
    
    YYChatMarqueeText *text = [[YYChatMarqueeText alloc] initWithAttributeString:str maxWidth:70];
    __weak YYChatMarqueeText *weaktext = text;
    YYChatMarqueeLabelView *label = [[YYChatMarqueeLabelView alloc] initWithFrame:CGRectMake(0, 0, weaktext.suggestedSize.width, weaktext.suggestedSize.height)];
    label.backgroundColor = [UIColor grayColor];
    label.marqueeText = weaktext;
    [self.view addSubview:label];
    
    label.center = self.view.center;
}

@end
