//
//  YYChatMarqueeLabel.m
//  YYChatMarqueeLabel
//
//  Created by ouzhirui on 2019/1/21.
//  Copyright © 2019年 ozr. All rights reserved.
//

#import "YYChatMarqueeLabelView.h"
#import <CoreText/CoreText.h>
#import <CoreGraphics/CoreGraphics.h>

@implementation YYChatMarqueeLabelView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (!self.marqueeText) {
        return;
    }
    
    //1.绘制必要的几部
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    //2.画文字
    CTFrameDraw(self.marqueeText.stringFrame, context);
    //3.画图片
    for (YYChatMarqueeTextAttachment *attachment in self.marqueeText.attachments) {
        if ([attachment.obj isKindOfClass:[UIImage class]]) {
            CGContextDrawImage(context,attachment.imageRect, ((UIImage *)(attachment.obj)).CGImage);
        }
    }
}

@end
