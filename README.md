# YYChatMarqueeLabelView

[![CI Status](https://img.shields.io/travis/673697831/YYChatMarqueeLabelView.svg?style=flat)](https://travis-ci.org/673697831/YYChatMarqueeLabelView)
[![Version](https://img.shields.io/cocoapods/v/YYChatMarqueeLabelView.svg?style=flat)](https://cocoapods.org/pods/YYChatMarqueeLabelView)
[![License](https://img.shields.io/cocoapods/l/YYChatMarqueeLabelView.svg?style=flat)](https://cocoapods.org/pods/YYChatMarqueeLabelView)
[![Platform](https://img.shields.io/cocoapods/p/YYChatMarqueeLabelView.svg?style=flat)](https://cocoapods.org/pods/YYChatMarqueeLabelView)

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Requirements

## Installation

YYChatMarqueeLabelView is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
# 版本1
pod 'YYChatMarqueeLabelView', :git => 'https://github.com/673697831/YYChatMarqueeLabelView.git', :commit => '9d14b9372b37d1358fe55648ae7c6876ac39ca8f'

```

```ruby
# 版本2 跑马灯业务
pod 'YYChatMarqueeLabelView', :git => 'https://github.com/673697831/YYChatMarqueeLabelView.git', :tag => ‘1.0.0’

```

## Author

ouzhirui, ouzhirui@yy.com

## License

YYChatMarqueeLabelView is available under the MIT license. See the LICENSE file for more info.

> 以下是基于 CoreText 的排版引擎,
> 基本实现和用法笔记

## dispatch_set_target_queue

创建一个子线程去做 CTFrameRef 的生成和高度的计算，并为队列设置低优先级

```objc
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
```

## dispatch_semaphore

生成加锁

```objc
_semaphore = dispatch_semaphore_create(1);
dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
dispatch_async(dispatch_get_marquee_queue(), ^{
    [self createFrameIfNeeded];
    dispatch_semaphore_signal(self.semaphore);
});
```

外部访问属性加锁

```objc
- (CTFrameRef)stringFrame
{
    CTFrameRef ref;
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    ref = self.myStringFrame;
    dispatch_semaphore_signal(self.semaphore);
    return ref;
}
```

```objc
- (NSArray<YYChatMarqueeTextAttachment *> *)attachments
{
    NSArray<YYChatMarqueeTextAttachment *> *atts;
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    atts = self.mySttachments;
    dispatch_semaphore_signal(_semaphore);
    return atts;
}
```

```objc
- (CGSize)suggestedSize
{
    CGSize size;
    dispatch_semaphore_wait(_semaphore, DISPATCH_TIME_FOREVER);
    size = self.mySuggestedSize;
    dispatch_semaphore_signal(_semaphore);
    return self.size;
}
```

## CoreText 简介

- 我们常用的 UILabel 控件进行富文本的展示
- UILabel 的底层是基于 Text Kit
- 营收跑马灯富文本是基于 Text Kit 而不是 UILabel
- Text Kit 底层是 CoreText
- Text Kit 和 CoreText 的实现都是基于自定义 UIView，重写 drawRect 方法
  <img src="https://images2015.cnblogs.com/blog/791499/201612/791499-20161226102517382-1268805252.png" width = "619" height = "224" alt="图片名称" 
  align=center>

## CoreText 的基本实现步骤

- 自定义 View，重写 drawRect 方法，后面的操作均在其中进行
- 得到当前绘图上下问文，用于后续将内容绘制在画布上
- 将坐标系翻转
- 创建绘制的区域，写入要绘制的内容

```objc
@interface YYChatMarqueeLabelView : UIView
```

```objc

@implementation YYChatMarqueeLabelView

- (void)drawRect:(CGRect)rect
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
```

## 基于 CoreText 的基本封装

我们可以将功能拆分为以下几个类来完成

- YYChatMarqueeLabelView：一个显示用的类，仅仅负责渲染
- YYChatMarqueeText：一个模型类， 用于保存富文本的所有内容
- YYChatMarqueeTextAttachment：一个附件类, 用于保存图片附件和计算的高度
- YYChatMarqueeTextParser：一个工具类，用于转换和封装

这 4 个类的关系是这样的：

1.YYChatMarqueeText 被创建时需要传入 NSAttributedString，并在内部创建一个 YYChatMarqueeTextParser

2.YYChatMarqueeTextParser 会解析传入的 NSAttributedString 解析出包含图片的封装类 YYChatMarqueeTextAttachment

3.YYChatMarqueeText 根据传入 NSAttributedString 生成 CTFrame 并保存起来，把 YYChatMarqueeTextParser 生成的 YYChatMarqueeTextAttachment 也保存起来

4.创建 YYChatMarqueeLabelView，并传入刚创建的 YYChatMarqueeText

5.YYChatMarqueeLabelView 会在 drawRect 方法中取出 YYChatMarqueeText 的 CTFrame 进行渲染

6.YYChatMarqueeLabelView 会在 drawRect 方法中取出 YYChatMarqueeText 里面的 YYChatMarqueeTextAttachment 里面的 UIImage 进行渲染

![关系图](https://github.com/673697831/YYChatMarqueeLabelView/blob/master/doc/rela.png?raw=true)
