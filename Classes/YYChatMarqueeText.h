//
//  YYChatMarqueeText.h
//  YYChatMarqueeLabel
//
//  Created by ouzhirui on 2019/1/22.
//  Copyright © 2019年 ozr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>
#import "YYChatMarqueeTextAttachment.h"

NS_ASSUME_NONNULL_BEGIN

@interface YYChatMarqueeText : NSObject

- (instancetype)initWithAttributeString:(NSAttributedString *)attributeString maxWidth:(CGFloat)maxWidth;

@property (nonatomic) CTFrameRef stringFrame;
@property (nonatomic, strong) NSArray<YYChatMarqueeTextAttachment *> *attachments;
@property (nonatomic) CGSize suggestedSize;

@end

NS_ASSUME_NONNULL_END
