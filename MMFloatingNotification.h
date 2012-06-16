//
//  MMFloatingNotification.h
//  MammothIV
//
//  Created by Yichao Peak Ji on 11-8-16.
//  Copyright 2011 PeakJi Design. All rights reserved.
//  www.peakji.com | blog.peakji.com | peakji@gmail.com | @peakji
//

#import <UIKit/UIKit.h>

@class MMFloatingNotification;

//--------------------------Configuration----------------------------
//-------------------------------------------------------------------
//Scale
#define kFloatingNotificationBoundsOvalWidth 5
#define kFloatingNotificationBoundsOvalHeight 5
#define kFloatingNotificationBoundsSizeFactor 1.0

//Animation Time
#define kFloatingNotificationMovingToKeyFrameTiming 0.8
#define kFloatingNotificationMovingToDestinationFrameTiming 0.6
#define kFloatingNotificationMovedToDestinationDisappearingTiming 0.6
//-------------------------------------------------------------------


//Floating Notification Bar Layout
typedef enum{		
    FloatingNotificationTypeNone=0,             //Only for initializing; Empty notifications will NOT present even if you've added it as a subview;
    FloatingNotificationTypeTextOnly,           //A notification bar with text and a roundrect background;
    FloatingNotificationTypeImageOnly,          //A notification bar with a single image and a roundrect background;
    FloatingNotificationTypeTextIcon,           //A notification bar with a small image as an icon on the left side and text on the right;
    FloatingNotificationTypeSubtitle,           //A notification bar with two lines of text: title on top while subtitle on the bottom in a smaller font size.
} MMFloatingNotificationType;


//Floating Notification Delegate
@protocol MMFloatingNotificationDelegate <NSObject>
@optional
//Called when the floating notification moved to the destination frame(and disappeared).
-(void)floatingNotificationDidMoveToDestinationFrame:(MMFloatingNotification *)floatingNotification;
@end


@interface MMFloatingNotification : UIImageView{
    BOOL isRetinaDisplay;   //Detect whether the screen supports retina display or not.
}

//Properties
@property(nonatomic,assign) id<MMFloatingNotificationDelegate> delegate;
@property(nonatomic,strong)NSString * title;
@property(nonatomic,strong)NSString * subtitle;
@property(nonatomic,strong)UIImage * icon;
@property(nonatomic,readwrite)MMFloatingNotificationType type;


//Initializing
-(id)init;
-(id)initWithImage:(UIImage *)_image;
-(id)initWithTitle:(NSString *)_title;-(id)initWithTitle:(NSString *)_title subtitle:(NSString *)_subtitle; 
-(id)initWithTitle:(NSString *)_title image:(UIImage *)_image;

//Movements
//(int)speedFactor:default as 1.0x speed.
-(void)startAnimationCycleFromFrame:(CGRect)startUpFrame throughKeyFrame:(CGRect)keyFrame toDestinationFrame:(CGRect)destinationFrame;
-(void)startAnimationCycleFromFrame:(CGRect)startUpFrame throughKeyFrame:(CGRect)keyFrame toDestinationFrame:(CGRect)destinationFrame atSpeed:(float)speedFactor; 
-(void)startAnimationCycleFromFrame:(CGRect)startUpFrame throughKeyFrame:(CGRect)keyFrame toDestinationFrame:(CGRect)destinationFrame withAutoDisappearing:(BOOL)autoDisappear; 
-(void)startAnimationCycleFromFrame:(CGRect)startUpFrame throughKeyFrame:(CGRect)keyFrame toDestinationFrame:(CGRect)destinationFrame atSpeed:(float)speedFactor withAutoDisappearing:(BOOL)autoDisappear;

//Actions
-(CGSize)getDefaultSizeInScale:(float)scaleFactor; 


-(void)render;
static void drawFloatingNotificationBackground(CGContextRef context, CGRect rect);
@end
