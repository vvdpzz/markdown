//
//  ViewController.h
//  markdown
//
//  Created by  on 12-5-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <DropboxSDK/DropboxSDK.h>
#import "TablePopoverController.h"
@class DBRestClient;

@interface ViewController : UIViewController
<UITextViewDelegate, UIGestureRecognizerDelegate, tablePopoverControllerDelegate>
{
    DBRestClient *restClient;
    BOOL working;
}

@property (strong, nonatomic) IBOutlet UIWebView *previewWebView;
@property (strong, nonatomic) IBOutlet UITextView *markdownTextView;
@property (strong, nonatomic) UIPanGestureRecognizer *panGesture;
@property (strong, nonatomic) UIView *keyboardView;
@property (strong, nonatomic) UIView *expandedView;
@property (nonatomic) NSRange startRange;
@property (nonatomic) CGPoint startLocation;
@property (nonatomic) CGRect keyboardFrame;
@property (nonatomic) BOOL isExpand;
@property (nonatomic) CGRect oldFrame;
@property (nonatomic) CGPoint previewPoint;
@property (nonatomic) CGRect panFrame;

@property (weak, nonatomic) IBOutlet UIButton *saveBtn;
@property (weak, nonatomic) IBOutlet UIButton *syncBtn;
@property (weak, nonatomic) IBOutlet UITextField *fileNameField;
@property (strong, nonatomic) IBOutlet UIButton *fileListBtn;
@property (strong, nonatomic) IBOutlet UIButton *settingBtn;

@property(nonatomic, retain) UIPopoverController *popoverController;
@property(nonatomic, retain) TablePopoverController *tablePopoverController;

@property (strong, nonatomic) NSString *muoPath;
@property (strong, nonatomic) NSString *muoFolder;
@property (strong, nonatomic) NSMutableArray *itemInDropboxArray;
@property (strong, nonatomic) NSMutableArray *itemInDeviceArray;
@property (strong, nonatomic) NSMutableArray *itemAtBothSideArray;
@property (strong, nonatomic) UISwitch *dropboxSwitch;
@property (strong, nonatomic) NSString *mkFileName;
@property (strong, nonatomic) NSString *automdFileName;
@property (strong, nonatomic) NSTimer *autoSaveTimer;
@end
