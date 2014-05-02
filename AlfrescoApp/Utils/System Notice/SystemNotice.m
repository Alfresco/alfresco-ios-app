//
//  SystemNotice.m
//

#import <QuartzCore/QuartzCore.h>

#import "SystemNotice.h"
#import "SystemNoticeManager.h"


static CGFloat const kSystemNoticeAlpha = 0.95f;

@interface SystemNotice ()
@property (nonatomic, assign) SystemNoticeStyle noticeStyle;
@property (nonatomic, weak) UIView *viewToDisplayOn;
@property (nonatomic, strong) UIColor *systemNoticeBackgroundColour;
@property (nonatomic, strong) NSString *icon;
@property (nonatomic, strong) UIColor *labelColor;
@property (nonatomic, strong) UIColor *shadowColor;
@property (nonatomic, strong) NSString *defaultTitle;
@property (nonatomic, weak) UILabel *titleLabel;
@property (nonatomic, weak) UILabel *messageLabel;
@property (nonatomic, assign) CGFloat offsetY;
@end

@implementation SystemNotice

CGFloat hiddenYOrigin;

#pragma mark - Public API

- (id)initWithStyle:(SystemNoticeStyle)style inView:(UIView *)view
{
    if (self = [super init])
    {
        self.viewToDisplayOn = view;
        
        switch (style)
        {
            case SystemNoticeStyleInformation:
                self.systemNoticeBackgroundColour = [UIColor systemNoticeInformationColor];
                self.icon = @"system_notice_tick.png";
                self.labelColor = [UIColor whiteColor];
                self.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.2];
                self.displayTime = 2.0f;
                break;
                
            case SystemNoticeStyleError:
                self.systemNoticeBackgroundColour = [UIColor systemNoticeErrorColor];
                self.icon = @"system_notice_explanation.png";
                self.labelColor = [UIColor whiteColor];
                self.shadowColor = [UIColor colorWithWhite:0.0 alpha:0.2];
                self.defaultTitle = NSLocalizedString(@"An Error Occurred", @"Default title for error notification");
                self.displayTime = 8.0f;
                break;
            
            case SystemNoticeStyleWarning:
                self.systemNoticeBackgroundColour = [UIColor systemNoticeWarningColor];
                self.icon = @"system_notice_explanation.png";
                self.labelColor = [UIColor blackColor];
                self.shadowColor = [UIColor colorWithWhite:1.0 alpha:0.2];
                self.displayTime = 3.0f;
                break;

            default:
                return nil;
        }
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    if ([object class] == [SystemNotice class])
    {
        SystemNotice *test = (SystemNotice *)object;
        if (test.noticeStyle == self.noticeStyle &&
            [test.title isEqualToString:self.title] &&
            [test.message isEqualToString:self.message])
        {
            return YES;
        }
    }
    return NO;
}

- (void)show
{
    [self createNotice];
    [[SystemNoticeManager sharedManager] queueSystemNotice:self];
}

#pragma mark - Internal Create & View methods

- (void)canDisplay
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationWillChange:) name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
    [self displayNotice];
}

- (void)createNotice
{
    // Get the view width, allowing for rotations
    CGRect rotatedView = CGRectApplyAffineTransform(self.viewToDisplayOn.frame, self.viewToDisplayOn.transform);
    CGFloat viewWidth = rotatedView.size.width;
    
    // Status Bar Height - [[UIApplication sharedApplication] statusBarFrame].size.height yields 1024 occasionally on iOS 7
    CGFloat statusBarHeight = 20.0f;
    
    // Padding
    CGFloat paddingBetweenMessageLabelAndBottonOfView = 10.0f;
    
    CGFloat messageLineHeight = 15.0;
    CGFloat originY = (self.message) ? statusBarHeight : 25.0;
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(55.0, originY, viewWidth - 70.0, 16.0)];
    titleLabel.textColor = self.labelColor;
    titleLabel.font = [UIFont systemFontOfSize:14.0];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.text = (self.title != nil) ? self.title : self.defaultTitle;
    
    // Message label
    UILabel *messageLabel = nil;
    if (self.message)
    {
        messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(55.0, 10.0 + 10.0, viewWidth - 70.0, messageLineHeight)];
        messageLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13.0f];
        messageLabel.textColor = self.labelColor;
        messageLabel.backgroundColor = [UIColor clearColor];
        messageLabel.text = self.message;
        messageLabel.numberOfLines = 0;
        messageLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        
        CGRect rect = messageLabel.frame;
        rect.origin.y = titleLabel.frame.origin.y + titleLabel.frame.size.height;
        
        // Prevent UILabel centering the text in the middle
        [messageLabel sizeToFit];
        
        // Determine the height of the message
        messageLineHeight = 5.0 + messageLabel.frame.size.height;
        rect.size.height = messageLabel.frame.size.height;
        rect.size.width = viewWidth - 70.0;
        messageLabel.frame = rect;
    }
    
    // Calculate the notice view height
    float noticeViewHeight = 25.0 + messageLineHeight + paddingBetweenMessageLabelAndBottonOfView;
    
    // Allow for shadow when hiding
    hiddenYOrigin = 0.0 - noticeViewHeight - 20.0;
    
    // Setup the view
    CGRect frameRect = CGRectMake(0.0, hiddenYOrigin, viewWidth, noticeViewHeight + 10.0);
    self.frame = frameRect;
    self.backgroundColor = self.systemNoticeBackgroundColour;
    self.alpha = kSystemNoticeAlpha;
    [self.viewToDisplayOn addSubview:self];
    
    // Icon view
    UIImageView *iconView = [[UIImageView alloc] initWithFrame:CGRectMake(12.0, statusBarHeight, 32.0, 32.0)];
    iconView.tintColor = self.labelColor;
    iconView.image = [[UIImage imageNamed:self.icon] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.alpha = 0.9;
    [self addSubview:iconView];
    
    // Title label
    [self addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    // Message label
    [self addSubview:messageLabel];
    self.messageLabel = messageLabel;
    
    // Invisible button to manually dismiss the notice
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    [button addTarget:self action:@selector(dismissNotice) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:button];
}

- (void)displayNotice
{
    [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
        CGRect newFrame = self.frame;
        newFrame.origin.y = self.offsetY;
        self.frame = newFrame;
    } completion:^(BOOL finished){
        [self performSelector:@selector(dismissNotice) withObject:nil afterDelay:self.displayTime];
    }];
}

- (void)dismissNotice
{
    [self dismissNoticeAnimated:YES];
}

- (void)dismissNoticeAnimated:(BOOL)animated
{
    if (animated)
    {
        [UIView animateWithDuration:0.5f delay:0 options:UIViewAnimationOptionCurveEaseOut animations:^{
            CGRect newFrame = self.frame;
            newFrame.origin.y = hiddenYOrigin;
            self.frame = newFrame;
        } completion:^(BOOL finished){
            [self removeFromSuperview];
            [[SystemNoticeManager sharedManager] systemNoticeDidDisappear:self];
        }];
    }
    else
    {
        [self removeFromSuperview];
        [[SystemNoticeManager sharedManager] systemNoticeDidDisappear:self];
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Device Orientation Notification

- (void)orientationWillChange:(NSNotification *)notification
{
    UIInterfaceOrientation orientation = [notification.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    
    if (IS_IPAD && UIInterfaceOrientationIsLandscape(orientation))
    {
        [self dismissNotice];
    }
}

#pragma mark - Class Methods

+ (SystemNotice *)showInformationNoticeInView:(UIView *)view message:(NSString *)message
{
    // We use the title for a simple information message type
    SystemNotice *notice = [SystemNotice systemNoticeWithStyle:SystemNoticeStyleInformation inView:view message:nil title:message];
    [notice show];
    return notice;
}

+ (SystemNotice *)showInformationNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title
{
    SystemNotice *notice =  [SystemNotice systemNoticeWithStyle:SystemNoticeStyleInformation inView:view message:message title:title];
    [notice show];
    return notice;
}

+ (SystemNotice *)showErrorNoticeInView:(UIView *)view message:(NSString *)message
{
    // An error type without specified title will be given a generic "An Error Occurred" title
    SystemNotice *notice =  [SystemNotice systemNoticeWithStyle:SystemNoticeStyleError inView:view message:message title:nil];
    [notice show];
    return notice;
}

+ (SystemNotice *)showErrorNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title
{
    SystemNotice *notice =  [SystemNotice systemNoticeWithStyle:SystemNoticeStyleError inView:view message:message title:title];
    [notice show];
    return notice;
}

+ (SystemNotice *)showWarningNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title
{
    SystemNotice *notice =  [SystemNotice systemNoticeWithStyle:SystemNoticeStyleWarning inView:view message:message title:title];
    [notice show];
    return notice;
}

+ (SystemNotice *)systemNoticeWithStyle:(SystemNoticeStyle)style inView:(UIView *)view message:(NSString *)message title:(NSString *)title
{
    SystemNotice *notice =  [[SystemNotice alloc] initWithStyle:style inView:view];
    notice.message = message;
    notice.title = title;
    return notice;
}

@end
