//
//  SystemNoticeGradientView.m
//

#import <QuartzCore/QuartzCore.h>
#import "SystemNoticeGradientView.h"

CGFloat const kSystemNoticeGradientAlpha = 0.9f;

@interface SystemNoticeGradientView ()
@property (nonatomic, strong) UIColor *gradientTop;
@property (nonatomic, strong) UIColor *gradientBottom;
@property (nonatomic, strong) UIColor *firstTopLine;
@property (nonatomic, strong) UIColor *secondTopLine;
@property (nonatomic, strong) UIColor *firstBottomLine;
@property (nonatomic, strong) UIColor *secondBottomLine;
@end

@implementation SystemNoticeGradientView

+ (Class)layerClass
{
    return [CAGradientLayer class];
}

- (id)initGradientViewColor:(SystemNoticeGradientColor)color frame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        switch (color)
        {
            case SystemNoticeGradientColorBlue:
                self.gradientTop = [UIColor colorWithRed:37/255.0f green:122/255.0f blue:185/255.0f alpha:kSystemNoticeGradientAlpha];
                self.gradientBottom = [UIColor colorWithRed:18/255.0f green:96/255.0f blue:154/255.0f alpha:kSystemNoticeGradientAlpha];
                self.firstTopLine = [UIColor colorWithRed:105/255.0f green:163/255.0f blue:208/255.0f alpha:kSystemNoticeGradientAlpha];
                self.secondTopLine = [UIColor colorWithRed:46/255.0f green:126/255.0f blue:188/255.0f alpha:kSystemNoticeGradientAlpha];
                self.firstBottomLine = [UIColor colorWithRed:18/255.0f green:92/255.0f blue:149/255.0f alpha:kSystemNoticeGradientAlpha];
                self.secondBottomLine = [UIColor colorWithRed:4/255.0f green:45/255.0f blue:75/255.0f alpha:kSystemNoticeGradientAlpha];
                break;
            
            case SystemNoticeGradientColorRed:
                self.gradientTop = [UIColor colorWithRed:167/255.0f green:26/255.0f blue:20/255.0f alpha:kSystemNoticeGradientAlpha];
                self.gradientBottom = [UIColor colorWithRed:134/255.0f green:9/255.0f blue:7/255.0f alpha:kSystemNoticeGradientAlpha];
                self.firstTopLine = [UIColor colorWithRed:211/255.0f green:82/255.0f blue:80/255.0f alpha:kSystemNoticeGradientAlpha];
                self.secondTopLine = [UIColor colorWithRed:193/255.0f green:30/255.0f blue:23/255.0f alpha:kSystemNoticeGradientAlpha];
                self.firstBottomLine = [UIColor colorWithRed:134/255.0f green:9/255.0f blue:7/255.0f alpha:kSystemNoticeGradientAlpha];
                self.secondBottomLine = [UIColor colorWithRed:52/255.0f green:4/255.0f blue:3/255.0f alpha:kSystemNoticeGradientAlpha];
                break;
            
            case SystemNoticeGradientColorYellow:
                self.gradientTop = [UIColor colorWithRed:251/255.0f green:223/255.0f blue:124/255.0f alpha:kSystemNoticeGradientAlpha];
                self.gradientBottom = [UIColor colorWithRed:240/255.0f green:204/255.0f blue:87/255.0f alpha:kSystemNoticeGradientAlpha];
                self.firstTopLine = [UIColor colorWithRed:253/255.0f green:229/255.0f blue:184/255.0f alpha:kSystemNoticeGradientAlpha];
                self.secondTopLine = [UIColor colorWithRed:253/255.0f green:229/255.0f blue:144/255.0f alpha:kSystemNoticeGradientAlpha];
                self.firstBottomLine = [UIColor colorWithRed:196/255.0f green:158/255.0f blue:46/255.0f alpha:kSystemNoticeGradientAlpha];
                self.secondBottomLine = [UIColor colorWithRed:98/255.0f green:79/255.0f blue:23/255.0f alpha:kSystemNoticeGradientAlpha];
                break;
                
            default:
                return nil;
        }
        [self createSubviews];
    }
    
    return self;
}

- (void)createSubviews
{
    CAGradientLayer *gradient = (CAGradientLayer *)[self layer];
    gradient.colors = [NSArray arrayWithObjects:
                       (id)self.gradientTop.CGColor,
                       (id)self.gradientBottom.CGColor,
                       nil];
    gradient.locations = [NSArray arrayWithObjects:
                          [NSNumber numberWithFloat:0.0f],
                          [NSNumber numberWithFloat:0.7],
                          nil];
    
    UIView *firstTopLine = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.bounds.size.width, 1.0)];
    firstTopLine.backgroundColor = self.firstTopLine;
    firstTopLine.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:firstTopLine];
    
    UIView *secondTopLine = [[UIView alloc] initWithFrame:CGRectMake(0.0, 1.0, self.bounds.size.width, 1.0)];
    secondTopLine.backgroundColor = self.secondTopLine;
    secondTopLine.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:secondTopLine];
    
    UIView *firstBottomLine = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.bounds.size.height - 1, self.frame.size.width, 1.0)];
    firstBottomLine.backgroundColor = self.firstBottomLine;
    firstBottomLine.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:firstBottomLine];
    
    UIView *secondBottomLine = [[UIView alloc] initWithFrame:CGRectMake(0.0, self.bounds.size.height, self.frame.size.width, 1.0)];
    secondBottomLine.backgroundColor = self.secondBottomLine;
    secondBottomLine.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    [self addSubview:secondBottomLine];
}

@end

