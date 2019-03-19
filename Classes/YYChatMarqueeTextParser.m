//
//  YYChatMarqueeTextParser.m
//  Pods-YYChatMarqueeLabelView_Example
//
//  Created by ouzhirui on 2019/2/14.
//

#import "YYChatMarqueeTextParser.h"
#import "YYChatMarqueeTextAttachment.h"

@implementation YYChatMarqueeTextParser

- (void)parseText:(NSAttributedString *)text
{
    self.rectOffsetY = 0;
    NSMutableAttributedString *myStr = [NSMutableAttributedString new];
    NSMutableArray *attachments = [NSMutableArray new];
    [text enumerateAttributesInRange:NSMakeRange(0, text.length) options:0 usingBlock:^(NSDictionary<NSAttributedStringKey,id> * _Nonnull attrs, NSRange range, BOOL * _Nonnull stop) {
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
                NSDictionary *dicPic = @{@"height":@(attachment.bounds.size.height),@"width":@(attachment.bounds.size.width), @"x":[NSString stringWithFormat:@"%@", @(attachment.bounds.origin.x)], @"y":[NSString stringWithFormat:@"%@", @(attachment.bounds.origin.y)], @"attchment":chatAtrachment};
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
                
                if (attachment.bounds.origin.y < self.rectOffsetY) {
                    self.rectOffsetY = attachment.bounds.origin.y;
                }
                
                CFRelease(delegate);
            }
        }else
        {
            [myStr appendAttributedString:[text attributedSubstringFromRange:range]];
        }
    }];
    
    self.mySttachments = attachments;
    self.chatMarqueeText = myStr;
}

- (void)updateImageRect:(CTFrameRef)frame
{
    NSArray *attchments = self.mySttachments;
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
                    CGFloat x = [dic[@"x"] floatValue];
                    CGFloat y = [dic[@"y"] floatValue];
                    boundsRun.size.width = CTRunGetTypographicBounds(run, CFRangeMake(0, 0), &ascent, &descent, NULL);
                    boundsRun.size.height = ascent + descent;
                    CGFloat xOffset = CTLineGetOffsetForStringIndex(line, CTRunGetStringRange(run).location, NULL);
                    boundsRun.origin.x = point.x + xOffset + x;
                    boundsRun.origin.y = point.y - descent + y;
                    CGPathRef path = CTFrameGetPath(frame);
                    CGRect colRect = CGPathGetBoundingBox(path);
                    CGRect imageBounds = CGRectOffset(boundsRun, colRect.origin.x, colRect.origin.y);
                    attchment.imageRect = imageBounds;
                    break;
                }
            }
        }
    }
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

@end
