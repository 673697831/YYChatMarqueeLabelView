//
//  YYChatMarqueeText.m
//  YYChatMarqueeLabel
//
//  Created by ouzhirui on 2019/1/22.
//  Copyright © 2019年 ozr. All rights reserved.
//

#import "YYChatMarqueeText.h"
#import "YYChatMarqueeTextParser.h"

dispatch_queue_t dispatch_get_marquee_queue() {
    static dispatch_queue_t marquee_queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!marquee_queue) {
            marquee_queue = dispatch_queue_create("com.yy.chat.marquee", DISPATCH_QUEUE_CONCURRENT);
            dispatch_queue_t globalQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0);
            dispatch_set_target_queue(marquee_queue, globalQueue);
        }
    });
    
    return marquee_queue;
}

@interface YYChatMarqueeText ()

@property (nonatomic, assign) CGFloat maxWidth;
@property (nonatomic, strong) NSAttributedString *attributeString;

@property (nonatomic) CTFrameRef myStringFrame;
@property (nonatomic, strong) NSArray<YYChatMarqueeTextAttachment *> *mySttachments;
@property (nonatomic) CGSize mySuggestedSize;
@property (nonatomic, strong) dispatch_semaphore_t semaphore;

@end

@implementation YYChatMarqueeText

#pragma mark - getter

- (CTFrameRef)stringFrame
{
    CTFrameRef ref;
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    ref = self.myStringFrame;
    dispatch_semaphore_signal(self.semaphore);
    return ref;
}

- (NSArray<YYChatMarqueeTextAttachment *> *)attachments
{
    NSArray<YYChatMarqueeTextAttachment *> *atts;
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    atts = self.mySttachments;
    dispatch_semaphore_signal(_semaphore);
    return atts;
}

- (CGSize)suggestedSize
{
    CGSize size;
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    size = self.mySuggestedSize;
    dispatch_semaphore_signal(_semaphore);
    return self.mySuggestedSize;
}

#pragma mark -

- (instancetype)initWithAttributeString:(NSAttributedString *)attributeString maxWidth:(CGFloat)maxWidth
{
    if (self = [self init]) {
        _maxWidth = maxWidth;
        _attributeString = attributeString;
        _mySuggestedSize = CGSizeZero;
        
        _semaphore = dispatch_semaphore_create(1);
        dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
        dispatch_async(dispatch_get_marquee_queue(), ^{
            [self createFrameIfNeeded];
            dispatch_semaphore_signal(self.semaphore);
        });
    }
    
    return self;
}

- (void)createFrameIfNeeded
{
    //1.字符串解析 把textkit里面所有附件解析成我们自己的附件
    YYChatMarqueeTextParser *textParser = [YYChatMarqueeTextParser new];
    [textParser parseText:self.attributeString];
    NSAttributedString *myStr = textParser.chatMarqueeText;
    CGFloat offsetY = textParser.rectOffsetY;
    self.mySttachments = textParser.mySttachments;
    
    //2.算出整个富文本所占宽高并存起来
    CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)myStr);
    CGFloat widthConstraint = self.maxWidth; // Your width constraint, using 500 as an example
    CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
                                                                        frameSetter, /* Framesetter */
                                                                        CFRangeMake(0, myStr.length), /* String range (entire string) */
                                                                        NULL, /* Frame attributes */
                                                                        CGSizeMake(widthConstraint, CGFLOAT_MAX), /* Constraints (CGFLOAT_MAX indicates unconstrained) */
                                                                        NULL /* Gives the range of string that fits into the constraints, doesn't matter in your situation */
                                                                        );
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, CGRectMake(0, -offsetY, suggestedSize.width, suggestedSize.height));
    NSInteger length = myStr.length;
    CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, length), path, NULL);
    self.myStringFrame = frame;
    self.mySuggestedSize = suggestedSize;
    
    CFRelease(path);
    CFRelease(frameSetter);
    
    //3.计算每个图片的位置并存起来
    [textParser updateImageRect:frame];
}

@end
