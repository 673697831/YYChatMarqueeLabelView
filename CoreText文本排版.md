
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

## CoreText 上下文
### 上下文是什么：
上下文定义了我们需要绘制的地方。

### 上下文是怎么工作的：
`UIKit` 维护着一个上下文堆栈，UIKit 方法总是绘制到最顶层的上下文中。你可以使用 `UIGraphicsGetCurrentContext()` 来得到最顶层的上下文。你可以使用 `UIGraphicsPushContext()` 和 `UIGraphicsPopContext()` 在 `UIKit` 的堆栈中推进或取出上下文。最为突出的是，`UIKit` 使用 `UIGraphicsBeginImageContextWithOptions()` 和 `UIGraphicsEndImageContext()` 方便的创建类似于 `CGBitmapContextCreate()` 的位图上下文。混合调用 `UIKit` 和 `Core Graphics` 非常简单：

## 描绘设置好的文本
```objc
void CTFrameDraw(CTFrameRef frame, CGContextRef context)
``` 

## 如何获得文本的frame信息？
需要计算文本所需的 `frame` ，需要用到
```objc
CTFrameRef CTFramesetterCreateFrame(CTFramesetterRef framesetter, CFRange stringRange, CGPathRef path,CFDictionaryRef frameAttributes);
```
* `framesetter` 用来创建 `frame`
* `stringRange` 用来创建 `framesetter` ，在排版时确定每一行的 `frame` 。如果 `range` 的 `length` 为0， `framesetter` 会继续添加行，直到把所有文本全部绘制完成或把给定的 `rect` 的范围用完。

## 如何获得文本的framesetter信息？
至于上面的参数 `framesetter` 从哪里来？作用是什么？
先举个栗子，使用
```objc
NSMutableAttributedString *attributedStr = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
CFAttributedStringRef attributedString = (__bridge CFAttributedStringRef)[self highlightText:attributedStr];
//Draw the frame
CTFramesetterRef framesetter = CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attributedString);
```

```objc
// 从attributeString创建一个可变的framesetter
CTFramesetterRef CTFramesetterCreateWithAttributedString(CFAttributedStringRef string);
```

`framesetter` 是用来创建和填充 `text` 的frame的。也就是从字符串到获取字符串的frame需要经过：

`NSString` —— `NSAttributedString` —— `CFAttributedStringRef` —— `CTFramesetterRef` —— `CTFrameRef`


## 绘制路径CGMutablePathRef

* `CGMutablePathRef` 是一个可变的路径，可通过 `CGPathCreateMutable()` 创建，该路径在被创建后，需要加到 `Context`中
* `CGPathAddRect` 就是将上面的路径添加到上下文中的方法。通常如下
```objc
// 从attributeString创建一个可变的framesetter
CTFramesetterRef CTFramesetterCreateWithAttributedString(CFAttributedStringRef string);
```

* `*m` 是一个指向仿射变换矩阵的指针，如果不需要可以设置为 `NULL`，如果指定了矩阵，`Core Graphics` 将转换应用于矩形，然后将其添加到路径中。
* `rect` 就是需要将该矩阵添加到哪里。

## 描绘的长度

```objc
CFRange stringRange = CFRangeMake(0, attributedStr.length);
```

## 文本所占空间计算

```objc
CGSize CTFramesetterSuggestFrameSizeWithConstraints(
    CTFramesetterRef framesetter,
    CFRange stringRange,
    CFDictionaryRef _Nullable frameAttributes,
    CGSize constraints,
    CFRange * _Nullable fitRange ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));
```

## 描绘文本信息

```objc
CGSize CTFramesetterSuggestFrameSizeWithConstraints(
    CTFramesetterRef framesetter,
    CFRange stringRange,
    CFDictionaryRef _Nullable frameAttributes,
    CGSize constraints,
    CFRange * _Nullable fitRange ) CT_AVAILABLE(macos(10.5), ios(3.2), watchos(2.0), tvos(9.0));
```

## 描绘设置好的图片

```objc
CG_EXTERN void CGContextDrawImage(CGContextRef cg_nullable c, CGRect rect,
    CGImageRef cg_nullable image)
    CG_AVAILABLE_STARTING(10.0, 2.0);
```

## TextKit 简介

- 渲染过程


```objc
@implementation YYChatMarqueeLabel

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    if (self.chatModel && [self.chatModel respondsToSelector:@selector(getLayoutManagerWithWidth:)] &&
        [self.chatModel respondsToSelector:@selector(chatTextStorage)]) {

        NSLayoutManager *layoutManager = [self.chatModel getLayoutManagerWithWidth:self.maxHeight];
        NSTextStorage *textStorage = [self.chatModel chatTextStorage];

        @autoreleasepool {
            // TextKit 渲染，性能好些
            if (layoutManager && textStorage) {
                NSRange glyphRange = [layoutManager glyphRangeForCharacterRange:NSMakeRange(0, textStorage.length)
                                                           actualCharacterRange:NULL];
                [layoutManager drawGlyphsForGlyphRange:glyphRange atPoint:CGPointZero];
                return;
            }

            // 备份渲染方式
            if ([self.chatModel respondsToSelector:@selector(attributedString)]) {
                [self.chatModel.attributedString
                    drawWithRect:rect
                         options:NSStringDrawingUsesLineFragmentOrigin | NSStringDrawingUsesFontLeading
                         context:nil];
                return;
            }
        }
    }
}
```

- 计算过程，在 `NSObject+TextKit`

```objc
- (CGRect)getFitRectWithWidth:(NSNumber *)width {
    if (!width) {
        return CGRectZero;
    }

    NSLayoutManager *chatLayoutManager = [[NSLayoutManager alloc] init];
    NSTextContainer *chatTextContainer = [[NSTextContainer alloc] initWithSize:CGSizeMake(width.floatValue, MAXFLOAT)];

    chatTextContainer.lineFragmentPadding = 0.0f;

    [chatLayoutManager addTextContainer:chatTextContainer];
    chatLayoutManager.delegate = self;
    
    NSTextStorage *textStorage = self.chatTextStorage;

    if (!textStorage) {
        if (self.attributedString) {
            textStorage = [[NSTextStorage alloc] initWithAttributedString:self.attributedString];
        } else {
            textStorage = [[NSTextStorage alloc] initWithString:@""];
        }
```

## 性能对比和优化
* 自己用 `CoreText` 实现跑马灯会比 `TextKit` 生成的时间本来就短
* 用 `CoreText` 实现跑马灯会比 `TextKit` 更加灵活
* 把非渲染部分放到子线程那里，因为跑马灯是一个一个播放的，在收到广播之后可以在子线程那里做预处理
* 非渲染部分包括计算宽高和生成文字和图片