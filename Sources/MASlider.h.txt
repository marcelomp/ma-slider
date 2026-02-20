//
//  MASlider.h
//  Pods
//
//  Created by Marcelo Mendes on 07/04/17.
//
//

#import <UIKit/UIKit.h>

#import <UIKit/UIKit.h>

@class MASlider;

@protocol MASliderDataSource <NSObject>

- (NSAttributedString *)slider:(MASlider *)slider titleForIndex:(NSInteger)index;

@end

IB_DESIGNABLE
@interface MASlider : UIControl

@property (nonatomic) IBInspectable NSUInteger step;
@property (nonatomic) IBInspectable NSUInteger numberOfSteps;
@property (strong, nonatomic) IBInspectable UIColor *trackTintColor;
@property (strong, nonatomic) IBInspectable UIColor *thumbTintColor;
@property (strong, nonatomic) IBInspectable UIImage *thumbImage;
@property (strong, nonatomic) IBInspectable NSString *stepText;
@property (strong, nonatomic) IBInspectable NSAttributedString *attributedStepText;
@property (strong, nonatomic) IBInspectable NSString *selectedStepText;
@property (strong, nonatomic) IBInspectable NSAttributedString *attributedSelectedStepText;

@property (weak, nonatomic) id<MASliderDataSource> dataSource;

- (void)setStep:(NSInteger)step animated:(BOOL)animated;

@end
