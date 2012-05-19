//
//  TablePopoverController.h
//  cursorControl
//
//  Created by xiaodong xue on 12-5-17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TablePopoverController;
@protocol tablePopoverControllerDelegate <NSObject>
-(void)controller:(TablePopoverController *)controller editTextContent:(NSString *)textContent;
@end

@interface TablePopoverController : UITableViewController<UITableViewDataSource,UITableViewDelegate>

@property (strong, nonatomic) NSMutableArray *itemArray;
@property (strong, nonatomic) NSString *muoPath;
@property (strong, nonatomic) id <tablePopoverControllerDelegate> delegate;

@end
