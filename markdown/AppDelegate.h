//
//  AppDelegate.h
//  markdown
//
//  Created by 陈振宇 & 薛晓东 on 12-5-5.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <DropboxSDK/DropboxSDK.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, DBSessionDelegate>

@property (strong, nonatomic) UIWindow *window;

@end
