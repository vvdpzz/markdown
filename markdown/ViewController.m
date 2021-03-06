//
//  ViewController.m
//  markdown
//
//  Created by 陈振宇 & 薛晓东 on 12-5-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "GHMarkdownParser.h"
#import "MMFloatingNotification.h"

#import <DropboxSDK/DropboxSDK.h>
#import "TablePopoverController.h"


@interface ViewController ()<DBRestClientDelegate>

@property (nonatomic, readonly) DBRestClient* restClient;

@end

@implementation ViewController
@synthesize previewWebView;

@synthesize keyboardView, markdownTextView, expandedView;
@synthesize startRange, startLocation;
@synthesize panGesture;
@synthesize keyboardFrame;
@synthesize isExpand, oldFrame, previewPoint, panFrame;

@synthesize fileListBtn;
@synthesize settingBtn;
@synthesize saveBtn,fileNameField;
@synthesize createMDBtn;
@synthesize syncBtn,restClient,muoPath,muoFolder,itemInDropboxArray,popoverController,itemInDeviceArray,itemAtBothSideArray,tablePopoverController,dropboxSwitch,mkFileName,automdFileName,autoSaveTimer,toolbar,toolbarItem,infoLabel;

- (void)initToolbar{
    toolbar = [[UIToolbar alloc] initWithFrame:CGRectMake(0.0, (self.view.frame.size.height/2) - 44.0, markdownTextView.frame.size.width, 44.0)];
    self.toolbar.autoresizingMask = UIViewAutoresizingFlexibleTopMargin;
    
    [self.view addSubview: toolbar];
}

-(void) insertOnly
{
    [self insertString:@"xxd" intoTextView:markdownTextView];
}

- (void) insertString: (NSString *) insertingString intoTextView: (UITextView *) textView
{
    NSRange range = textView.selectedRange;  
    NSString * firstHalfString = [textView.text substringToIndex:range.location];
    NSString * secondHalfString = [textView.text substringFromIndex: range.location];  
    textView.scrollEnabled = NO;
    
    textView.text = [NSString stringWithFormat: @"%@%@%@",  
                     firstHalfString,  
                     insertingString,  
                     secondHalfString];  
    range.location += [insertingString length];  
    textView.selectedRange = range;  
    textView.scrollEnabled = YES; 
}

- (void) insertAtFirstPlace: (NSString *) insertingString intoTextView: (UITextView *) textView
{
    UITextRange *textRange = [markdownTextView selectedTextRange];
    CGRect rect = [markdownTextView caretRectForPosition:textRange.start];
    UITextPosition *start = [markdownTextView closestPositionToPoint:CGPointMake(0, rect.origin.y)];
    [markdownTextView setSelectedTextRange:[markdownTextView textRangeFromPosition:start toPosition:start]];
    
    NSRange range = textView.selectedRange;
    NSString * firstHalfString = [textView.text substringToIndex:range.location];  
    NSString * secondHalfString = [textView.text substringFromIndex: range.location];  
    textView.scrollEnabled = NO;
    
    textView.text = [NSString stringWithFormat: @"%@%@%@",  
                     firstHalfString,  
                     insertingString,  
                     secondHalfString];  
    range.location += [insertingString length];  
    textView.selectedRange = range;  
    textView.scrollEnabled = YES; 
}

-(void) setH1 {[self insertAtFirstPlace:@"# " intoTextView:markdownTextView];}
-(void) SetCode {[self insertAtFirstPlace:@"\n    " intoTextView:markdownTextView];}

-(void) setImage
{
    [self insertString:@"![Image](link)" intoTextView:markdownTextView];
    NSRange range = markdownTextView.selectedRange;
    range.location = range.location - 5;
    range.length = 4;
    self.markdownTextView.selectedRange = range;
}

-(void) setBlockquotes {[self insertAtFirstPlace:@"> " intoTextView:markdownTextView];}
-(void) setAsterisk {[self insertAtFirstPlace:@"* " intoTextView:markdownTextView];}

- (void)initToolbarItems{
    UIBarButtonItem *flexible = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    
    UIBarButtonItem *h1Item = [[UIBarButtonItem alloc] initWithTitle:@"H1" style:UIBarButtonItemStylePlain target:self action:@selector(setH1)];
    UIBarButtonItem *h2Item   = [[UIBarButtonItem alloc] initWithTitle:@"Image"   style:UIBarButtonItemStylePlain target:self action:@selector(setImage)];
    UIBarButtonItem *blockquotesItem = [[UIBarButtonItem alloc] initWithTitle:@">" style:UIBarButtonItemStylePlain target:self action:@selector(setBlockquotes)];
    UIBarButtonItem *asteriskItem  = [[UIBarButtonItem alloc] initWithTitle:@"*"  style:UIBarButtonItemStylePlain target:self action:@selector(setAsterisk)];
    UIBarButtonItem *codeItem  = [[UIBarButtonItem alloc] initWithTitle:@"<code>"  style:UIBarButtonItemStylePlain target:self action:@selector(SetCode)];
    
    //[imageItem setTag:0];
    
    toolbarItem = [NSMutableArray arrayWithObjects: h1Item, flexible, h2Item, flexible,blockquotesItem, flexible,asteriskItem, flexible,codeItem, nil];
    [self.toolbar setItems:toolbarItem animated:YES];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self initToolbar];
    [self initToolbarItems];
    self.markdownTextView.delegate = self;
    [self.markdownTextView becomeFirstResponder];
    [self relayout];
    fileNameField.hidden = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardDidChangeFrame:) name:UIKeyboardDidChangeFrameNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fullscreen:)];
    tapGesture.numberOfTouchesRequired = 2;
    [self.previewWebView addGestureRecognizer:tapGesture];
    
    UITapGestureRecognizer *tapMGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(fullscreen:)];
    tapMGesture.numberOfTouchesRequired = 2;
    [self.markdownTextView addGestureRecognizer:tapMGesture];
    isExpand = NO;
    
    [self createMuoPath];
    [self listMarkdownFile];
    
    [syncBtn addTarget:self action:@selector(syncMarkdownFile) forControlEvents:UIControlEventTouchUpInside];
    [fileListBtn addTarget:self action:@selector(listFileButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [settingBtn addTarget:self action:@selector(settingButtonAction) forControlEvents:UIControlEventTouchUpInside];
    [saveBtn addTarget:self action:@selector(saveMarkdownFile) forControlEvents:UIControlEventTouchUpInside];
    [createMDBtn addTarget:self action:@selector(createNewFile) forControlEvents:UIControlEventTouchUpInside];
    autoSaveTimer=[NSTimer scheduledTimerWithTimeInterval:3 
                                           target:self 
                                         selector:@selector(autoSaveFile) 
                                         userInfo:nil 
                                          repeats:YES]; 
}

- (void)fullscreen:(UIGestureRecognizer *)gestureRecognizer{
    self.expandedView = gestureRecognizer.view;
    if (isExpand == NO) {
        oldFrame = self.expandedView.frame;
        CGRect frame = self.view.frame;
        frame.origin.x = 0;
        frame.origin.y = 0;
        if (self.interfaceOrientation == UIInterfaceOrientationLandscapeLeft || self.interfaceOrientation == UIInterfaceOrientationLandscapeRight){
            frame.size.width = self.view.frame.size.height;
            frame.size.height = self.view.frame.size.width;
        }
        self.expandedView.frame = frame;
        isExpand = TRUE;
    } else {
        self.expandedView.frame = oldFrame;
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
        self.markdownTextView.frame = CGRectMake(0, 30, weight, height);
        self.previewWebView.frame = CGRectMake(weight, 0, weight, height);
    }else {
        float weight = self.view.frame.size.width;
        float height = self.view.frame.size.height / 2;
        self.markdownTextView.frame = CGRectMake(0, 30, weight, height);
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
    [self setFileNameField: nil];
    [self setSaveBtn: nil];
    [self setFileListBtn:nil];
    [self setSettingBtn:nil];
    
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

-(void) settingButtonAction
{    
    UIViewController* popoverContent = [[UIViewController alloc]init];
    UIView* popoverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 300)];
    popoverView.backgroundColor = [UIColor whiteColor];
    
    dropboxSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 30, 150, 40)];
    
    UILabel *dropboxFolder = [[UILabel alloc] initWithFrame:CGRectMake(20, 57, 150, 40)];
    dropboxFolder.text = @"Dropbox folder: /App/Muo";
    dropboxFolder.font = [UIFont systemFontOfSize:12];
    dropboxFolder.textColor = [UIColor grayColor];
    [dropboxSwitch addTarget:self action:@selector(dropboxSwitch:) forControlEvents:UIControlEventValueChanged];
    if (![[DBSession sharedSession] isLinked]) {
        [dropboxSwitch setOn:NO animated:NO];
    } else {
        [dropboxSwitch setOn:YES animated:NO];
    }
    [popoverView addSubview:dropboxSwitch];
    [popoverView addSubview:dropboxFolder];
    
    popoverContent.view = popoverView;
    popoverContent.contentSizeForViewInPopover = CGSizeMake(200, 300);
    
    self.popoverController = [[UIPopoverController alloc]
                              initWithContentViewController:popoverContent];
    [self.popoverController presentPopoverFromRect:settingBtn.frame
                                            inView:self.view
                          permittedArrowDirections:UIPopoverArrowDirectionAny
                                          animated:YES];
}

- (void)dropboxSwitch:(id)sender {
    if (dropboxSwitch.on) 
    {
        NSLog(@"dropboxSwitch On");
        if (![[DBSession sharedSession] isLinked]) {
            [[DBSession sharedSession] link];
            [self.restClient loadMetadata:@"/"];
        }
    } else {
        NSLog(@"dropboxSwitch Off");
        [[DBSession sharedSession] unlinkAll];
        [[[UIAlertView alloc] 
          initWithTitle:@"Account Unlinked!" message:@"Your dropbox account has been unlinked" 
          delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
         show];
    }
}

-(void) listFileButtonAction{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:[NSBundle mainBundle]];
    tablePopoverController = [storyboard instantiateViewControllerWithIdentifier:@"tableViewSB"];
    tablePopoverController.contentSizeForViewInPopover = CGSizeMake(200, 300);
    
    UIViewController* popoverContent = [[UIViewController alloc]init];
    UIView* popoverView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 200, 300)];
    popoverView.backgroundColor = [UIColor clearColor];
    
    popoverContent.view = popoverView;
    popoverContent.contentSizeForViewInPopover = CGSizeMake(200, 300);
    self.popoverController = [[UIPopoverController alloc]
                              initWithContentViewController:tablePopoverController];
    [self.popoverController presentPopoverFromRect:fileListBtn.frame
                                            inView:self.view
                          permittedArrowDirections:UIPopoverArrowDirectionAny
                                          animated:YES];
    tablePopoverController.delegate = self;
}

- (DBRestClient *)restClient {
    if (!restClient) {
        restClient =
        [[DBRestClient alloc] initWithSession:[DBSession sharedSession]];
        restClient.delegate = self;
    }
    return restClient;
}

- (void)restClient:(DBRestClient *)client loadMetadataFailedWithError:(NSError *)error {
    NSLog(@"Error loading metadata: %@", error);
}
- (void)restClient:(DBRestClient*)client loadedFile:(NSString*)localPath {
    NSLog(@"File loaded into path: %@", localPath);
}
- (void)restClient:(DBRestClient*)client loadFileFailedWithError:(NSError*)error {
    NSLog(@"There was an error loading the file - %@", error);
}
- (void)restClient:(DBRestClient*)client uploadedFile:(NSString*)destPath
              from:(NSString*)srcPath metadata:(DBMetadata*)metadata {
    NSLog(@"File uploaded successfully to path: %@", metadata.path);
}
- (void)restClient:(DBRestClient*)client uploadFileFailedWithError:(NSError*)error {
    NSLog(@"File upload failed with error - %@", error);
}

- (void) mkUpload{
    NSString *dropboxPath = @"/";
    for (NSString *localMD in itemInDeviceArray) {
        NSLog(@"Device has %@ md file(s)",itemInDeviceArray);
        NSLog(@"Dropbox has:%@ md file(s)",itemInDropboxArray);
        if ([[[localMD substringFromIndex: [localMD length] - 2] uppercaseString]isEqualToString:@"MD"]){
            NSString *localPath =[muoPath stringByAppendingPathComponent:localMD];
            if (![itemInDropboxArray containsObject:localMD]) {
                [[self restClient] uploadFile:localMD toPath:dropboxPath withParentRev:nil fromPath:localPath];
                NSLog(@"Uploading %@ from %@ to %@",localMD, localPath,dropboxPath);
            }
        }
    }
}

-(void) mkDownload{
    NSString *dropboxPath = @"/";
    for (NSString *dropboxMD in itemInDropboxArray) {
        if ([[[dropboxMD substringFromIndex: [dropboxMD length] - 2] uppercaseString]isEqualToString:@"MD"]){
            if (![itemInDeviceArray containsObject:dropboxMD]) {
                NSLog(@"itemInDeviceArray not contain %@",dropboxMD);
                NSString *localPath =[muoPath stringByAppendingPathComponent:dropboxMD];
                NSString *dropboxMDFile =[dropboxPath stringByAppendingPathComponent:dropboxMD];
                [self.restClient loadFile:dropboxMDFile intoPath:localPath];
                NSLog(@"Downloading %@ from %@ to %@",dropboxMDFile,dropboxPath,localPath);
            }
        }
    }
}

- (void)restClient:(DBRestClient *)client loadedMetadata:(DBMetadata *)metadata {
    //    NSArray* validExtensions = [NSArray arrayWithObjects:@"mk", @"markdown", nil];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    itemInDeviceArray = [[fileManager contentsOfDirectoryAtPath:muoPath error:&error]mutableCopy];
    [itemInDeviceArray removeObject:@".DS_Store"];
    for (NSString *itemInDevice in itemInDeviceArray)
    { 
        NSLog(@"itemInDeviceArray contains %@",itemInDevice);
    }
    NSString *dropboxPath = @"/";
    
    self.itemInDropboxArray = [[NSMutableArray alloc]init];
    for (DBMetadata *child in metadata.contents) {
        NSString *itemName = [[child.path pathComponents] lastObject];
        [self.itemInDropboxArray addObject:itemName];
    }
    
    self.itemAtBothSideArray = [[NSMutableArray alloc]init];
    NSLog(@"Let's check the Date!");
    for (NSString *itemInDevice in itemInDeviceArray)
    { 
        if([itemInDropboxArray containsObject:itemInDevice] && ![itemAtBothSideArray containsObject:itemInDevice])
            [itemAtBothSideArray addObject:itemInDevice];
    }
    // 1 首先同步文件版本
    NSEnumerator *e= [metadata.contents objectEnumerator];
    DBMetadata *dbObject;
    NSString *code;
    while ((dbObject = [e nextObject])) {
        if (!dbObject.isDirectory) {
            code = [[dbObject.path substringFromIndex: [dbObject.path length] - 2]uppercaseString];
            if ([code isEqualToString: @"MD"]) {
                NSString *fileNames = [dbObject.path lastPathComponent]; //找到最上层文件夹例如/Muo中的/xxd.md
                NSMutableArray* filesAndProperties = [NSMutableArray arrayWithCapacity:[itemInDeviceArray count]];
                NSError* error = nil;
                NSDictionary* properties;
                
                for (NSString *file in itemInDeviceArray) {
                    NSString *localPath =[muoPath stringByAppendingPathComponent:file];
                    properties = [[NSFileManager defaultManager]attributesOfItemAtPath:localPath error:&error];
                    NSDate* modDate = [properties objectForKey:NSFileModificationDate];
                    if(error == nil) {
                        [filesAndProperties addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                                       file, @"path",
                                                       modDate, @"lastModDate",
                                                       nil]];                 
                    }
                    if ([[NSString stringWithFormat: @"/%@",file] isEqualToString:dbObject.path] && nil != modDate && modDate.timeIntervalSinceReferenceDate < dbObject.lastModifiedDate.timeIntervalSinceReferenceDate) {
                        [self.restClient loadFile:[NSString stringWithFormat: @"%@%@", dropboxPath, file]
                                         intoPath:localPath];
                    }
                    else if ([[NSString stringWithFormat: @"/%@",file] isEqualToString:dbObject.path] && nil != modDate && modDate.timeIntervalSinceReferenceDate > dbObject.lastModifiedDate.timeIntervalSinceReferenceDate) {
                        [[self restClient] uploadFile:fileNames toPath:dropboxPath fromPath:localPath];
                    }
                }
            }
        }
    }
    
    //2 同步相互没有的文件
    if (![itemInDeviceArray isEqualToArray:itemInDropboxArray]) 
    {
        if ([itemInDeviceArray count] < [itemInDropboxArray count]) {
            [self mkDownload];   
        } else if ([itemInDeviceArray count] > [itemInDropboxArray count]){
            [self mkUpload]; 
        } else {
            [self mkDownload]; 
            [self mkUpload]; 
        }
    } else {
        NSLog(@"Local and Dropbox contain exactly same Markdown files");
    }
}

-(void) syncMarkdownFile
{
    [self.restClient loadMetadata:@"/"];
}

- (BOOL) isEmptyString:(NSString *) string {
    if([string length] == 0) {
        return YES;
    } else if([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        return YES;
    }
    return NO;
}

- (void)createNewFile
{
    NSString *autoFileName = [muoFolder stringByAppendingPathComponent:@"Unsaved"];
    automdFileName = [autoFileName stringByAppendingString:@".md"];
    NSLog(@"automdFileName 建立了？%@",automdFileName);
    BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:automdFileName];
    if (blHave) {
        infoLabel.text = @"Please save your unsaved file";
        infoLabel.textColor = [UIColor lightGrayColor];
        [UIView beginAnimations:@"textFades" context:nil];
        [UIView setAnimationDuration:5];
        [infoLabel setEnabled:NO];
        [infoLabel setAlpha:0.0];
        [UIView commitAnimations];
        BOOL bSave = [self saveMarkdownFile];
        if (bSave) {
        }else {
            NSLog(@"保存失败，需要检查saveMarkdownFile");
            return;
        }
    }else {
        mkFileName = @"";
        NSLog(@"mkFileName 清空了？%@",mkFileName);
        markdownTextView.text=@"";
        infoLabel.text = @"Created a new file";
        infoLabel.textColor = [UIColor lightGrayColor];
        [UIView beginAnimations:@"textFades" context:nil];
        [UIView setAnimationDuration:5];
        [infoLabel setEnabled:NO];
        [infoLabel setAlpha:0.0];
        [UIView commitAnimations];
    }
}

- (void)autoSaveFile{
    if ([self isEmptyString:mkFileName]==NO) {
        //NSLog(@"自定义名称的文件存在");
        NSString *savedString = markdownTextView.text;
        BOOL result = [savedString writeToFile:mkFileName atomically:YES encoding:NSUTF8StringEncoding error: nil];
        if (result) {
            //NSLog(@"文件自动保存到%@成功！",mkFileName);
        }else {
            NSLog(@"文件自动保存到%@失败！",mkFileName);
        }
    }else {
        //NSLog(@"没有文件需要创建");
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *mdFileName = [muoFolder stringByAppendingPathComponent:@"Unsaved"];
        automdFileName = [mdFileName stringByAppendingString:@".md"];
        if (![fileManager fileExistsAtPath:mkFileName]) {
            NSString *savedString = markdownTextView.text;
            BOOL result = [savedString writeToFile:automdFileName atomically:YES encoding:NSUTF8StringEncoding error: nil];
            if (result) {
                //NSLog(@"文件自动保存到%@成功！",automdFileName);
            }else {
                NSLog(@"文件自动保存到%@失败！",automdFileName);
            }
        }
    }
}

-(void) saveFlag {
    MMFloatingNotification * floatingNotification=[[MMFloatingNotification alloc] initWithTitle:@"Saved!"];
    [floatingNotification render];
    floatingNotification.image=[[UIImage alloc] init];
    [self.view addSubview:floatingNotification];
    int max_width=320;
    int max_height=480;
    [floatingNotification startAnimationCycleFromFrame:
     CGRectMake(max_width/2-[floatingNotification getDefaultSizeInScale:3].width/2,-10,
                [floatingNotification getDefaultSizeInScale:3].width, 
                [floatingNotification getDefaultSizeInScale:3].height) 
                                       throughKeyFrame:CGRectMake(
                                                                  (max_width-[floatingNotification getDefaultSizeInScale:2.0].width)/2, max_height/2-60, 
                                                                  [floatingNotification getDefaultSizeInScale:2.0].width, [floatingNotification getDefaultSizeInScale:2.0].height) toDestinationFrame:CGRectMake((max_width-[floatingNotification getDefaultSizeInScale:2].width)/2, max_height-20,[floatingNotification getDefaultSizeInScale:2].width, [floatingNotification getDefaultSizeInScale:2].height)];
    floatingNotification=nil;
}

- (BOOL)saveMarkdownFile{
    if ([self isEmptyString:mkFileName]==NO) {
        //如果文件已经保存过，就追加保存
        NSString *savedString = markdownTextView.text;
        BOOL result = [savedString writeToFile:mkFileName atomically:YES encoding:NSUTF8StringEncoding error: nil];

        if (result) {
            NSLog(@"文件已经追加保存");
            return YES;
            infoLabel.text =  @"saved";
            infoLabel.textColor = [UIColor lightGrayColor];
            [UIView beginAnimations:@"textFades" context:nil];
            [UIView setAnimationDuration:5];
            [infoLabel setEnabled:NO];
            [infoLabel setAlpha:0.0];
            [UIView commitAnimations];
        }else {
            NSLog(@"写入文件失败");
            return NO;
        }
    }else {
        NSLog(@"文件已经保存");
        if (fileNameField.hidden == YES) {
            fileNameField.hidden = NO;
            UIImage *imgDone = [UIImage imageNamed:@"Done.png"];
            [saveBtn setImage:imgDone forState:UIControlStateNormal];
        } else {
            //如果点击的时候名称输入框是打开的情况
            fileNameField.textAlignment = UITextAlignmentCenter;
            if ([fileNameField.text length] > 0) {
                //判断名称输入栏不为空
                NSString *fileNamed = fileNameField.text;
                NSFileManager *fileManager = [NSFileManager defaultManager];
                NSString *mdFileName = [muoFolder stringByAppendingPathComponent:fileNamed];
                mkFileName = [mdFileName stringByAppendingString:@".md"];
                NSString *autoFileName = [muoFolder stringByAppendingPathComponent:@"Unsaved"];
                automdFileName = [autoFileName stringByAppendingString:@".md"];
                BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:automdFileName];
                NSLog(@"mkFileName: %@",mkFileName);
                if (![fileManager fileExistsAtPath:mkFileName]) {
                    //如果建立文件成功，将uitextview内容写入文件
                    NSString *savedString = markdownTextView.text;
                    BOOL result = [savedString writeToFile:mkFileName atomically:YES encoding:NSUTF8StringEncoding error: nil];
                    if (result) {
                        NSLog(@"文件创建成功！");
                        infoLabel.text =  [NSString stringWithFormat:@"%@.md saved",fileNameField.text];
                        UIImage *imgSaveDisk = [UIImage imageNamed:@"SaveDisk.png"];
                        [saveBtn setImage:imgSaveDisk forState:UIControlStateNormal];
                        infoLabel.textColor = [UIColor lightGrayColor];
                        [UIView beginAnimations:@"textFades" context:nil];
                        [UIView setAnimationDuration:5];
                        [infoLabel setEnabled:NO];
                        [infoLabel setAlpha:0.0];
                        [UIView commitAnimations];
                        if (!blHave) {
                            return YES;
                        }else {
                            BOOL blDele= [fileManager removeItemAtPath:automdFileName error:nil];
                            if (blDele) {
                                NSLog(@"unsaved删除成功");
                            }else {
                                NSLog(@"unsaved删除失败");
                            }
                        }
                        fileNameField.hidden = YES;
                        [saveBtn setTitle:@"Saved" forState:UIControlStateNormal];
                        [UIView beginAnimations:nil context:nil];
                        [UIView setAnimationDuration:1];
                        [saveBtn setTitle:@"Save" forState:UIControlStateNormal];
                        [UIView commitAnimations];
                    }else {
                        NSLog(@"文件创建失败！");
                    }
                }
            } else {
                fileNameField.placeholder = @"Please name your file";
            }
        }
    }
}

- (void)createMuoPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *documentPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES); 
    NSString *documentsDirectory = [documentPaths objectAtIndex:0];
    muoFolder = [documentsDirectory stringByAppendingPathComponent:@"Muo"];
    if (![fileManager fileExistsAtPath:muoFolder]) {
        BOOL blCreateFolder= [fileManager createDirectoryAtPath:muoFolder withIntermediateDirectories:NO attributes:nil error:NULL]; 
        if (blCreateFolder) {
            NSLog(@"文件夹建立成功！");
        }else {
            NSLog(@"文件夹建立失败！");
        }
    } else {
        NSLog(@"文件夹已经存在！");
    }
}

- (void)listMarkdownFile{
    NSString *document=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    muoPath =[document stringByAppendingPathComponent:@"Muo"];
    NSLog(@"muoPath:%@",muoPath);
}

-(id)contentsForType:(NSString *)typeName 
               error:(NSError *__autoreleasing *)outError
{
    return [NSData dataWithBytes:[self.markdownTextView.text UTF8String] 
                          length:[self.markdownTextView.text length]];
} 
-(BOOL) loadFromContents:(id)contents 
                  ofType:(NSString *)typeName 
                   error:(NSError *__autoreleasing *)outError
{
    if ( [contents length] > 0) {
        self.markdownTextView.text = [[NSString alloc] 
                              initWithBytes:[contents bytes] 
                              length:[contents length] 
                              encoding:NSUTF8StringEncoding];
    } else {
        self.markdownTextView.text = @"";
    }
    return YES;
}

-(void)controller:(TablePopoverController *)controller editTextContent:(NSString *)textContent{
    NSLog(@"received");
    self.markdownTextView.text = textContent;
}
@end
