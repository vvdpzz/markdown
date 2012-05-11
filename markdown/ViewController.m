//
//  ViewController.m
//  markdown
//
//  Created by 陈振宇 on 12-5-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

@synthesize keyboardView, markdownTextView;
@synthesize startRange, startLocation;
@synthesize panGesture;

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShowOnDelay:) name:UIKeyboardWillShowNotification object:nil];
}

- (void)keyboardWillShowOnDelay:(NSNotification *)notification
{
    [self performSelector:@selector(keyboardWillShow:) withObject:nil afterDelay:0];
}

- (UIView *)findKeyboard {
    
    UIWindow *keyboardWindow = nil;
    for (UIWindow *testWindow in [[UIApplication sharedApplication] windows]) {
        if (![[testWindow class] isEqual:[UIWindow class]]) {
            keyboardWindow = testWindow;
            break;
        }
    }
    
    UIView *foundKeyboard = nil;
    for (UIView __strong *possibleKeyboard in [keyboardWindow subviews]) {
        
        if ([[possibleKeyboard description] hasPrefix:@"<UIPeripheralHostView"]) {
            possibleKeyboard = [[possibleKeyboard subviews] objectAtIndex:0];
        }
        
        if ([[possibleKeyboard description] hasPrefix:@"<UIKeyboard"]) {
            foundKeyboard = possibleKeyboard;
            break;
        }
    }
    return foundKeyboard;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    keyboardView = [self findKeyboard];
    if (keyboardView) 
    {
        BOOL gestureNotFound = YES;
        for (UIGestureRecognizer *gesture in [keyboardView gestureRecognizers]) {
            if([gesture isKindOfClass:[UIPanGestureRecognizer class]]){
                gestureNotFound = NO;
                break;
            }
        }
        if (gestureNotFound) {
            panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGesture:)];
            [keyboardView addGestureRecognizer:panGesture];
        }
    }
}

- (void)moveCursor:(long)length{
    self.markdownTextView.selectedRange = NSMakeRange(startRange.location + length, startRange.length);
}

- (void)panGesture:(UIPanGestureRecognizer *)sender {
    if (sender.state == UIGestureRecognizerStateBegan) {
        startLocation = [sender locationInView:self.keyboardView];
        startRange = [self.markdownTextView selectedRange];
    }
    else if (sender.state == UIGestureRecognizerStateChanged) {
        CGPoint offset = [sender translationInView:self.keyboardView];
        int w = 768;
        if (keyboardView.frame.size.height == 1024) {
            w = 1024;
        }
        int pointsChanged = offset.x * 120 / w;
        int newLocation = startRange.location;
        int newLength = startRange.length;
        
        int textLength = [self.markdownTextView.text length];
        
        newLocation += pointsChanged;
        
        if (newLocation > textLength) {
            newLocation = textLength;
        }
        else if (newLocation < 0) {
            newLocation = 0;
        }
        
        [self.markdownTextView setSelectedRange:NSMakeRange(newLocation, newLength)];
    }
}

- (void)viewDidUnload
{
    [self setMarkdownTextView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

@end
