//
//  SystemNotice.h
//

#import <Foundation/Foundation.h>

@interface SystemNotice : UIView

typedef enum
{
    SystemNoticeStyleInformation = 0,
    SystemNoticeStyleError,
    SystemNoticeStyleWarning
} SystemNoticeStyle;

@property (nonatomic, assign, readonly) SystemNoticeStyle noticeStyle;

/**
 * Public API
 */
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, assign) CGFloat displayTime;

- (id)initWithStyle:(SystemNoticeStyle)style inView:(UIView *)view;
- (void)show;

/**
 * Preferred API entrypoints
 */
// Note: Title label is used for a simple information message type
+ (SystemNotice *)showInformationNoticeInView:(UIView *)view message:(NSString *)message;
+ (SystemNotice *)showInformationNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title;
// Note: An error notice without given title will be given a generic "An Error Occurred" title
+ (SystemNotice *)showErrorNoticeInView:(UIView *)view message:(NSString *)message;
+ (SystemNotice *)showErrorNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title;
+ (SystemNotice *)showWarningNoticeInView:(UIView *)view message:(NSString *)message title:(NSString *)title;
+ (SystemNotice *)systemNoticeWithStyle:(SystemNoticeStyle)style inView:(UIView *)view message:(NSString *)message title:(NSString *)title;

@end
