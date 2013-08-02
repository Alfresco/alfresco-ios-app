//
//  SystemNoticeGradientView.h
//

#import <UIKit/UIKit.h>

@interface SystemNoticeGradientView : UIView

typedef enum
{
    SystemNoticeGradientColorBlue = 0,
    SystemNoticeGradientColorRed,
    SystemNoticeGradientColorYellow
} SystemNoticeGradientColor;

- (id)initGradientViewColor:(SystemNoticeGradientColor)color frame:(CGRect)frame;

@end
