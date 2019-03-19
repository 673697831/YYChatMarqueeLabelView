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

- (void)setMarqueeText:(YYChatMarqueeText *)marqueeText
{
    _marqueeText = marqueeText;
    [self setNeedsDisplay];
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        //异步描绘，提高性能？
        self.layer.drawsAsynchronously = YES;
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super initWithCoder:aDecoder]) {
        self.backgroundColor = [UIColor clearColor];
        //异步描绘，提高性能？
        self.layer.drawsAsynchronously = YES;
    }
    
    return self;
}

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    if (!self.marqueeText) {
        return;
    }
    
    //得到上下文
    CGContextRef context = UIGraphicsGetCurrentContext();
    //坐标翻转
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    //创建绘制内容
    //绘制
    //画文字
    CTFrameDraw(self.marqueeText.stringFrame, context);
    //画图片
    for (YYChatMarqueeTextAttachment *attachment in self.marqueeText.attachments) {
        if ([attachment.obj isKindOfClass:[UIImage class]]) {
            CGContextDrawImage(context,attachment.imageRect, ((UIImage *)(attachment.obj)).CGImage);
        }
    }
}

@end
