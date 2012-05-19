//
//  ViewController.m
//  markdown
//
//  Created by 陈振宇 on 12-5-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"
#import "GHMarkdownParser.h"

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
@synthesize linkDropboxBtn;
@synthesize settingBtn;
@synthesize saveBtn,fileNameField;
@synthesize syncBtn,restClient,muoPath, muoFolder, itemInDropboxArray,popoverController,itemInDeviceArray,itemAtBothSideArray,tablePopoverController;

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.markdownTextView.delegate = self;
    [self.markdownTextView becomeFirstResponder];
    [self relayout];
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
    [linkDropboxBtn addTarget:self action:@selector(didPressLink) forControlEvents:UIControlEventTouchUpInside];
    [settingBtn addTarget:self action:@selector(settingButtonAction) forControlEvents:UIControlEventTouchUpInside];
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
    
    [self setFileNameField: nil];
    [self setSaveBtn: nil];
    [self setFileListBtn:nil];
    [self setLinkDropboxBtn:nil];
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
    
    UISwitch *dropboxSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(20, 20, 150, 40)];
    [dropboxSwitch setOn:NO animated:YES];
    [popoverView addSubview:dropboxSwitch];
    
    popoverContent.view = popoverView;
    popoverContent.contentSizeForViewInPopover = CGSizeMake(200, 300);
    
    self.popoverController = [[UIPopoverController alloc]
                              initWithContentViewController:popoverContent];
    [self.popoverController presentPopoverFromRect:settingBtn.frame
                                            inView:self.view
                          permittedArrowDirections:UIPopoverArrowDirectionAny
                                          animated:YES];
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
}

- (void)didPressLink {
    if (![[DBSession sharedSession] isLinked]) {
        [[DBSession sharedSession] link];
        //[self.restClient loadMetadata:@"/"];
    } else {
        [[DBSession sharedSession] unlinkAll];
        [[[UIAlertView alloc] 
          initWithTitle:@"Account Unlinked!" message:@"Your dropbox account has been unlinked" 
          delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil]
         show];
        [self updateButtons];
    }
}
- (void)updateButtons {
    NSString* title = [[DBSession sharedSession] isLinked] ? @"Unlink Dropbox" : @"Link Dropbox";
    [linkDropboxBtn setTitle:title forState:UIControlStateDisabled];
    linkDropboxBtn.enabled = [[DBSession sharedSession] isLinked];
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
        NSString *localPath =[muoPath stringByAppendingPathComponent:localMD];
        if (![itemInDropboxArray containsObject:localMD]) {
            [[self restClient] uploadFile:localMD toPath:dropboxPath withParentRev:nil fromPath:localPath];
            NSLog(@"Uploading %@ from %@ to %@",localMD, localPath,dropboxPath);
        }
    }
}

-(void) mkDownload{
    NSString *dropboxPath = @"/";
    for (NSString *dropboxMD in itemInDropboxArray) {
        if (![itemInDeviceArray containsObject:dropboxMD]) {
            NSLog(@"itemInDeviceArray not contain %@",dropboxMD);
            NSString *localPath =[muoPath stringByAppendingPathComponent:dropboxMD];
            //NSString *dropboxMDFile = [NSString stringWithFormat:@"/%s",dropboxMD];
            NSString *dropboxMDFile =[dropboxPath stringByAppendingPathComponent:dropboxMD];
            [self.restClient loadFile:dropboxMDFile intoPath:localPath];
            NSLog(@"Downloading %@ from %@ to %@",dropboxMDFile,dropboxPath,localPath);
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
    while ((dbObject = [e nextObject])) {
        if (!dbObject.isDirectory) {
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

- (IBAction)saveMarkdownFile:(id)sender{
    if (fileNameField.hidden == YES) {
        fileNameField.hidden = NO;
        [saveBtn setTitle:@"OK" forState:UIControlStateNormal];
    } else {
        fileNameField.textAlignment = UITextAlignmentCenter;
        NSString *fileNamed = fileNameField.text;
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *mdFileName = [muoFolder stringByAppendingPathComponent:fileNamed];
        NSString *filePath = [mdFileName stringByAppendingString:@".md"];
        NSLog(@"filePath: %@",filePath);
        if (![fileManager fileExistsAtPath:filePath]) {
            NSString *savedString = markdownTextView.text;
            BOOL result = [savedString writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error: nil];
            if (result) {
                NSLog(@"文件创建成功！");
                fileNameField.hidden = YES;
                [saveBtn setTitle:@"Saved" forState:UIControlStateDisabled];
                [UIView beginAnimations:@"buttonFades" context:nil];
                [UIView setAnimationDuration:1];
                [saveBtn setEnabled:NO];
                [saveBtn setAlpha:0.0];
                [UIView commitAnimations];
            }else {
                NSLog(@"文件创建失败！");
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
@end
