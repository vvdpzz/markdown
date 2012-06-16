//
//  MMFloatingNotification.m
//  MammothIV
//
//  Created by Yichao Peak Ji on 11-8-16.
//  Copyright 2011 PeakJi Design. All rights reserved.
//

#import "MMFloatingNotification.h"

@implementation MMFloatingNotification

@synthesize title;
@synthesize subtitle;
@synthesize icon;
@synthesize type;
@synthesize delegate;

#pragma mark - Initializing

-(id)init
{
    self=[super init];
    if (self) {
        isRetinaDisplay=([UIScreen mainScreen].scale==2.0);
        self.title=nil;
        self.subtitle=nil;
        self.icon=nil;
        self.type=FloatingNotificationTypeNone;
        self.delegate=nil;
        self.image=nil;
        self.contentMode=UIViewContentModeScaleToFill;
    }
    return self;
}


-(id)initWithImage:(UIImage *)_image{
    self=[self init];
    self.icon=_image;
    self.type=FloatingNotificationTypeImageOnly;
    return self;
}

//Original

-(id)initWithTitle:(NSString *)_title{
    self=[self init];
    self.title=_title;
    self.type=FloatingNotificationTypeTextOnly;
    return self;
}


-(id)initWithTitle:(NSString *)_title subtitle:(NSString *)_subtitle{
    self=[self init];
    self.title=_title;
    self.subtitle=_subtitle;
    self.type=FloatingNotificationTypeSubtitle;
    return self;
}


-(id)initWithTitle:(NSString *)_title image:(UIImage *)_image{
    self=[self init];
    self.title=_title;
    self.icon=_image;
    self.type=FloatingNotificationTypeTextIcon;
    return self;
}



#pragma mark - Drawing

-(float)getMaxLength{
    float len=(5+20*[title length])*kFloatingNotificationBoundsSizeFactor;
    if(len>=320)len=320;
    return len;
}

-(CGSize)getDefaultSizeInScale:(float)scaleFactor{
    if(self.type==FloatingNotificationTypeNone)return CGSizeMake(0*scaleFactor, 0*scaleFactor);
    else if(self.type==FloatingNotificationTypeTextOnly)return CGSizeMake([self getMaxLength]*scaleFactor,30*kFloatingNotificationBoundsSizeFactor*scaleFactor);
    
    else return CGSizeMake(0, 0);
}

-(void)render{
    
    dispatch_queue_t rendering_Queue;
    rendering_Queue = dispatch_queue_create("com.hugehard.mammoth4.element_rendering", nil);
    
    dispatch_async(rendering_Queue, ^{
        
        float predictedWidth=0,predictedHeight=0;
        UIImage * notificationImage;
        if(self.type!=FloatingNotificationTypeNone)
        {
            if(self.type==FloatingNotificationTypeTextOnly)
            {
                predictedHeight=30*kFloatingNotificationBoundsSizeFactor;
                predictedWidth=[self getMaxLength];
            }
            UIGraphicsBeginImageContext(CGSizeMake(predictedWidth, predictedHeight)); 
            CGContextRef context=UIGraphicsGetCurrentContext();
            drawFloatingNotificationBackground(context, CGRectMake(0, 0, predictedWidth, predictedHeight));
            CGFloat fillColor[4]={1.0,0.5,0.5,1.0f};
            CGContextSetFillColor(context, fillColor);
            CGContextFillPath(context);
            
            CGContextSelectFont (context,"Arial",32,kCGEncodingMacRoman);
            CGContextSetCharacterSpacing (context, 10); 
            CGContextSetTextDrawingMode (context, kCGTextFill);
            CGContextSetRGBFillColor (context, 0, 0, 0, 1.0);
            __autoreleasing UIFont* font = [UIFont fontWithName:@"Arial" size:20.0];
            
            [title drawInRect:CGRectMake(0,3, predictedWidth, predictedHeight-10) withFont:font lineBreakMode:UILineBreakModeMiddleTruncation alignment:UITextAlignmentCenter];
            
            notificationImage= UIGraphicsGetImageFromCurrentImageContext();
            UIGraphicsEndImageContext();
            
            
        }
        dispatch_sync(dispatch_get_main_queue(), ^{ 
            self.image=notificationImage;
            
        });
        
    });
    
    
}




static void drawFloatingNotificationBackground(CGContextRef context, CGRect rect)
{    
    //Add a rectangle to the graphics context and return
    if (kFloatingNotificationBoundsOvalWidth==0||kFloatingNotificationBoundsOvalHeight==0)
    { 
        CGContextAddRect(context, rect);
        return;
    }
    
    CGContextSaveGState(context);
    CGContextTranslateCTM (context, CGRectGetMinX(rect),CGRectGetMinY(rect));
    CGContextScaleCTM(context,kFloatingNotificationBoundsOvalWidth,kFloatingNotificationBoundsOvalHeight);
    float arc_width=CGRectGetWidth(rect)/kFloatingNotificationBoundsOvalWidth;
    float arc_height=CGRectGetHeight(rect)/kFloatingNotificationBoundsOvalHeight;
    CGContextMoveToPoint(context, arc_width, arc_height/2);
    CGContextAddArcToPoint(context, arc_width, arc_height, arc_width/2, arc_height, 1);
    CGContextAddArcToPoint(context, 0, arc_height, 0, arc_height/2, 1);
    CGContextAddArcToPoint(context, 0, 0, arc_width/2, 0, 1);
    CGContextAddArcToPoint(context, arc_width, 0, arc_width, arc_height/2, 1);
    CGContextClosePath(context);
    CGContextRestoreGState(context);
}


#pragma mark - Actions



#pragma mark - Movements

-(void)startAnimationCycleFromFrame:(CGRect)startUpFrame throughKeyFrame:(CGRect)keyFrame toDestinationFrame:(CGRect)destinationFrame{
    [self startAnimationCycleFromFrame:startUpFrame throughKeyFrame:keyFrame toDestinationFrame:destinationFrame atSpeed:1.0 withAutoDisappearing:YES];
}


-(void)startAnimationCycleFromFrame:(CGRect)startUpFrame throughKeyFrame:(CGRect)keyFrame toDestinationFrame:(CGRect)destinationFrame atSpeed:(float)speedFactor{
    [self startAnimationCycleFromFrame:startUpFrame throughKeyFrame:keyFrame toDestinationFrame:destinationFrame atSpeed:speedFactor withAutoDisappearing:YES];
}


-(void)startAnimationCycleFromFrame:(CGRect)startUpFrame throughKeyFrame:(CGRect)keyFrame toDestinationFrame:(CGRect)destinationFrame withAutoDisappearing:(BOOL)autoDisappear{
    [self startAnimationCycleFromFrame:startUpFrame throughKeyFrame:keyFrame toDestinationFrame:destinationFrame atSpeed:1.0 withAutoDisappearing:autoDisappear];
}


-(void)startAnimationCycleFromFrame:(CGRect)startUpFrame throughKeyFrame:(CGRect)keyFrame toDestinationFrame:(CGRect)destinationFrame atSpeed:(float)speedFactor withAutoDisappearing:(BOOL)autoDisappear{
    if(self.superview!=nil&&self.image!=nil)
    {
        self.frame=startUpFrame;
        self.alpha=0.0;
        [UIView animateWithDuration:kFloatingNotificationMovingToKeyFrameTiming*speedFactor animations:^{
            self.frame=keyFrame;
            self.alpha=1.0;
        } 
                         completion:^(BOOL finished){
                             [UIView animateWithDuration:kFloatingNotificationMovingToDestinationFrameTiming*speedFactor animations:^{
                                 self.frame=destinationFrame;
                             } 
                                              completion:^(BOOL finished){
                                                  if(autoDisappear!=YES)
                                                  {
                                                      if(self.delegate!=nil)[self.delegate floatingNotificationDidMoveToDestinationFrame:self];
                                                  }
                                                  else
                                                  {
                                                      [UIView animateWithDuration:kFloatingNotificationMovedToDestinationDisappearingTiming*speedFactor animations:^{
                                                          self.alpha=0.0;
                                                      } 
                                                                       completion:^(BOOL finished){
                                                                           [self removeFromSuperview];
                                                                           if(self.delegate!=nil)[self.delegate floatingNotificationDidMoveToDestinationFrame:self];
                                                                       }];
                                                  }
                                              }];
                         }];
    }
}





@end
