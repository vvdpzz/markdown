//
//  ViewController.h
//  markdown
//
//  Created by  on 12-5-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController
@property (strong, nonatomic) IBOutlet UITextView *markdownTextView;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
@property (strong, nonatomic) UIView *keyboardView;
@property (nonatomic) NSRange startRange;
@property (nonatomic) CGPoint startLocation;
@end
