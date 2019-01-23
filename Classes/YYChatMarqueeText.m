//
//  YYChatMarqueeText.m
//  YYChatMarqueeLabel
//
//  Created by ouzhirui on 2019/1/22.
//  Copyright © 2019年 ozr. All rights reserved.
//

#import "YYChatMarqueeText.h"

@interface YYChatMarqueeText ()

@end

@implementation YYChatMarqueeText

- (instancetype)initWithAttributeString:(NSAttributedString *)attributeString maxWidth:(CGFloat)maxWidth
{
    if (self = [self init]) {
        
        //1.字符串解析 把textkit里面所有附件解析成我们自己的附件
        NSMutableAttributedString *myStr = [NSMutableAttributedString new];
        NSMutableArray *attachments = [NSMutableArray new];
        [attributeString enumerateAttributesInRange:NSMakeRange(0, attributeString.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
            NSTextAttachment *attachment = [attrs objectForKey:NSAttachmentAttributeName];
            if (attachment) {
                if ([attachment.image isKindOfClass:[UIImage class]]) {
                    YYChatMarqueeTextAttachment *chatAtrachment = [YYChatMarqueeTextAttachment new];
                    CTRunDelegateCallbacks callBacks;
                    memset(&callBacks,0,sizeof(CTRunDelegateCallbacks));
                    callBacks.version = kCTRunDelegateVersion1;
                    callBacks.getAscent = ascentCallBacks;
                    callBacks.getDescent = descentCallBacks;
                    callBacks.getWidth = widthCallBacks;
                    NSDictionary *dicPic = @{@"height":@(attachment.bounds.size.height),@"width":@(attachment.bounds.size.width), @"attchment":chatAtrachment};
                    CTRunDelegateRef delegate = CTRunDelegateCreate(& callBacks, (__bridge void *)dicPic);
                    unichar placeHolder = 0xFFFC;
                    NSString *placeHolderStr = [NSString stringWithCharacters:&placeHolder length:1];
                    NSMutableAttributedString *placeHolderAttrStr = [[NSMutableAttributedString alloc] initWithString:placeHolderStr];
                    CFAttributedStringSetAttribute((CFMutableAttributedStringRef)placeHolderAttrStr, CFRangeMake(0, 1), kCTRunDelegateAttributeName, delegate);
                    [myStr appendAttributedString:placeHolderAttrStr];
                    
                    chatAtrachment.type = kYYChatMarqueeTextAttachmentTypeImage;
                    chatAtrachment.obj = attachment.image;
                    chatAtrachment.dicPic = dicPic;
                    [attachments addObject:chatAtrachment];
                    
                    CFRelease(delegate);
                }
            }else
            {
                [myStr appendAttributedString:[attributeString attributedSubstringFromRange:range]];
            }
        }];
        
        //2.算出整个富文本所占宽高并存起来
        CTFramesetterRef frameSetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)myStr);
        CGFloat widthConstraint = maxWidth; // Your width constraint, using 500 as an example
        CGSize suggestedSize = CTFramesetterSuggestFrameSizeWithConstraints(
                                                                            frameSetter, /* Framesetter */
                                                                            CFRangeMake(0, myStr.length), /* String range (entire string) */
                                                                            NULL, /* Frame attributes */
                                                                            CGSizeMake(widthConstraint, CGFLOAT_MAX), /* Constraints (CGFLOAT_MAX indicates unconstrained) */
                                                                            NULL /* Gives the range of string that fits into the constraints, doesn't matter in your situation */
                                                                            );
        CGMutablePathRef path = CGPathCreateMutable();
        CGPathAddRect(path, NULL, CGRectMake(0, 0, suggestedSize.width, suggestedSize.height));
        NSInteger length = myStr.length;
        CTFrameRef frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(0, length), path, NULL);
        self.suggestedSize = suggestedSize;
        self.stringFrame = frame;
        
        //3.计算每个图片的位置并存起来
        [self calculateImageRectWithFrame:self.stringFrame attchments:attachments];
        self.attachments = attachments;
        
        //4.释放对象
        CFRelease(path);
        CFRelease(frameSetter);
      
    }
    
    return self;
}


static CGFloat ascentCallBacks(void * ref)
{
    return [(NSNumber *)[(__bridge NSDictionary *)ref valueForKey:@"height"] floatValue];
}
static CGFloat descentCallBacks(void * ref)
{
    return 0;
}
static CGFloat widthCallBacks(void * ref)
{
    return [(NSNumber *)[(__bridge NSDictionary *)ref valueForKey:@"width"] floatValue];
}

-(void)calculateImageRectWithFrame:(CTFrameRef)frame attchments:(NSArray<YYChatMarqueeTextAttachment *> *)attchments
{
    NSArray * arrLines = (NSArray *)CTFrameGetLines(frame);
    NSInteger count = [arrLines count];
    CGPoint points[count];
    CTFrameGetLineOrigins(frame, CFRangeMake(0, 0), points);
    for (int i = 0; i < count; i ++) {
        CTLineRef line = (__bridge CTLineRef)arrLines[i];
        NSArray * arrGlyphRun = (NSArray *)CTLineGetGlyphRuns(line);
        for (int j = 0; j < arrGlyphRun.count; j ++) {
            CTRunRef run = (__bridge CTRunRef)arrGlyphRun[j];
            NSDictionary * attributes = (NSDictionary *)CTRunGetAttributes(run);
            CTRunDelegateRef delegate = (__bridge CTRunDelegateRef)[attributes valueForKey:(id)kCTRunDelegateAttributeName];
            if (delegate == nil) {
                continue;
            }
            NSDictionary * dic = CTRunDelegateGetRefCon(delegate);
            if (![dic isKindOfClass:[NSDictionary class]]) {
                continue;
            }
            
            for (YYChatMarqueeTextAttachment *attchment in attchments) {
                if (dic[@"attchment"] == attchment) {
                    CGPoint point = points[i];
                    CGFloat ascent;
                    CGFloat descent;
                    CGRect boundsRun;
                    boundsRun.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
                    boundsRun.size.height = ascent + descent;
                    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
                    boundsRun.origin.x = point.x + xOffset;
                    boundsRun.origin.y = point.y - descent;
                    CGPathRef path = CTFrameGetPath(frame);
                    CGRect colRect = CGPathGetBoundingBox(path);
                    CGRect imageBounds = CGRectOffset(boundsRun, colRect.origin.x, colRect.origin.y);
                    attchment.imageRect = imageBounds;
                    break;
                }
            }
        }
    }}

@end
