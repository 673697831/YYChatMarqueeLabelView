//
//  YYChatMarqueeTextAttachment.h
//  YYChatMarqueeLabel
//
//  Created by ouzhirui on 2019/1/22.
//  Copyright © 2019年 ozr. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreText/CoreText.h>

typedef NS_ENUM(NSUInteger,YYChatMarqueeTextAttachmentType)
{
    kYYChatMarqueeTextAttachmentTypeImage,
    kYYChatMarqueeTextAttachmentTypeView
};

NS_ASSUME_NONNULL_BEGIN

@interface YYChatMarqueeTextAttachment : NSObject

@property (nonatomic, assign) YYChatMarqueeTextAttachmentType type;
@property (nonatomic, assign) CGRect imageRect;
@property (nonatomic, strong) id obj;//uiimage 或者 UIview
@property (nonatomic, strong) NSDictionary *dicPic;

@end

NS_ASSUME_NONNULL_END
