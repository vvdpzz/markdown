//
//  ViewController.m
//  markdown
//
//  Created by 陈振宇 on 12-5-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "GHMarkdownParser.h"

@interface ViewController ()

@end

@implementation ViewController
@synthesize previewWebView;

@synthesize keyboardView, markdownTextView;
@synthesize startRange, startLocation;
@synthesize panGesture;
@synthesize keyboardFrame;
@synthesize isExpand, oldFrame;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.markdownTextView.delegate = self;
    [self.markdownTextView becomeFirstResponder];
    [self relayout];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fullscreen)];
    tapGesture.numberOfTouchesRequired = 2;
    [self.previewWebView addGestureRecognizer:tapGesture];
    isExpand = NO;
}

- (void)fullscreen{
    if (isExpand == NO) {
        oldFrame = self.previewWebView.frame;
        CGRect frame = self.view.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight){
            frame.size.width = self.view.frame.size.height;
            frame.size.height = self.view.frame.size.width;
        }
        self.previewWebView.frame = frame;
        isExpand = TRUE;
    } else {
        self.previewWebView.frame = oldFrame;
        isExpand = NO;
    }
}

- (void)textViewDidChange:(UITextView *)textView{
    NSString *htmlHead = @"<html><head><link href ='style.css' rel='stylesheet' type=text/css'/></head><body>";
    NSString *compiled = self.markdownTextView.text.flavoredHTMLStringFromMarkdown;
    NSString *HTML = [NSString stringWithFormat:@"%@%@", htmlHead, compiled];
    [self.previewWebView loadHTMLString:HTML baseURL:[NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]]];
}

- (void)textViewDidBeginEditing:(UITextView *)textView{
    [self changeHeightDependsOnKeyboardFrame];
    [self textViewDidChange:self.markdownTextView];
}

- (void)textViewDidEndEditing:(UITextView *)textView{
    self.keyboardFrame = CGRectNull;
    [self changeHeightDependsOnKeyboardFrame];
}

- (void)relayout{
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight){
        float weight = self.view.frame.size.height / 2;
        float height = self.view.frame.size.width;
        self.markdownTextView.frame = CGRectMake(0, 0, weight, height);
        self.previewWebView.frame = CGRectMake(weight, 0, weight, height);
    }else {
        float weight = self.view.frame.size.width;
        float height = self.view.frame.size.height / 2;
        self.markdownTextView.frame = CGRectMake(0, 0, weight, height);
        self.previewWebView.frame = CGRectMake(0, height, weight, height);
    }
}

- (void)changeHeightDependsOnKeyboardFrame{
    if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight)
    {
        float height = self.view.frame.size.width;
        if (self.keyboardFrame.size.width && self.keyboardFrame.size.width > 0) {
            height -= self.keyboardFrame.size.width;
        }
        CGRect frame = self.markdownTextView.frame;
        frame.size.height = height;
        self.markdownTextView.frame = frame;
        
        frame = self.previewWebView.frame;
        frame.size.height = height;
        self.previewWebView.frame = frame;
    }else{
        float height = self.view.frame.size.height;
        if (self.keyboardFrame.size.height > 0) {
            height -= self.keyboardFrame.size.height;
        }
        CGRect frame = self.markdownTextView.frame;
        frame.size.height = height;
        self.markdownTextView.frame = frame;
        
        frame = self.previewWebView.frame;
        frame.size.height = height;
        self.previewWebView.frame = frame;
    }
}

- (UIView *)findKeyboard
{    
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

- (void)keyboardWasShown:(NSNotification *)notification
{
    keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self changeHeightDependsOnKeyboardFrame];
}

- (void)keyboardDidChangeFrame:(NSNotification *)notification
{
    keyboardFrame = [[[notification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
    [self changeHeightDependsOnKeyboardFrame];
        
    if (!keyboardView)
    {
        keyboardView = [self findKeyboard];
    }
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
            panGesture.maximumNumberOfTouches = 1;
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
    [self setPreviewWebView:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

- (void)print:(NSString *)whose frame:(CGRect)frame{
    NSLog(@"%@ %f %f %f %f", whose, frame.origin.x, frame.origin.y, frame.size.width, frame.size.height);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    [self relayout];
}

@end
