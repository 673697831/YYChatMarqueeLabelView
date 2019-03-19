//
//  YYChatMarqueeTextParser.h
//  Pods-YYChatMarqueeLabelView_Example
//
//  Created by ouzhirui on 2019/2/14.
//

#import <Foundation/Foundation.h>
#import <CoreText/CoreText.h>
#import <UIKit/UIKit.h>

@class YYChatMarqueeTextAttachment;

NS_ASSUME_NONNULL_BEGIN

@interface YYChatMarqueeTextParser : NSObject

@property (nonatomic, assign) CGFloat rectOffsetY;
@property (nonatomic, strong) NSArray<YYChatMarqueeTextAttachment *> *mySttachments;
@property (nonatomic, strong) NSAttributedString *chatMarqueeText;

- (void)parseText:(NSAttributedString *)text;
- (void)updateImageRect:(CTFrameRef)frame;

@end

NS_ASSUME_NONNULL_END
