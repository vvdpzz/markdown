//
//  TablePopoverController.m
//  cursorControl
//
//  Created by 陈振宇 & 薛晓东 on 12-5-17.
//  Copyright (c) 2012年 __MyCompanyName__. All rights reserved.
//

#import "TablePopoverController.h"
#import "ViewController.h"
@interface TablePopoverController ()

@end

@implementation TablePopoverController
@synthesize itemArray,muoPath,delegate;

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

-(void)deleteFile: (NSString *)mdFile {
    NSFileManager* fileManager=[NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *uniquePath=[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Muo"];
    NSString *filePath = [uniquePath stringByAppendingPathComponent:mdFile];
    NSLog(@"fileName is %@",filePath);
    BOOL blHave=[[NSFileManager defaultManager] fileExistsAtPath:filePath];
    if (!blHave) {
        NSLog(@"filePath doesn't exist");
        return ;
    }else {
        NSLog(@"filePath exist, I'll delete the md file");
        BOOL blDele= [fileManager removeItemAtPath:filePath error:nil];
        if (blDele) {
            [self createItemArray];
            NSLog(@"delete success");
        }else {
            NSLog(@"delete fail");
        }
    }
}

-(void)syncDropboxFile: (NSString *)fileName{
    NSFileManager* fileManager=[NSFileManager defaultManager];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES);
    NSString *uniquePath=[[paths objectAtIndex:0] stringByAppendingPathComponent:@"Muo"];
    NSString *syncDropboxFile=[uniquePath stringByAppendingPathComponent:@"syncDropbox"];
    NSString *filePath = [syncDropboxFile stringByAppendingString:@".txt"];
    if (![fileManager fileExistsAtPath:filePath]) {
        BOOL blCreateFile= [fileManager createFileAtPath:filePath contents:nil attributes:nil ]; 
        if (blCreateFile) {
            NSLog(@"syncDropbox.txt created!");
            [fileName writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error: nil];
        }else {
            NSLog(@"syncDropbox.txt fail!");
        }
    } else {
        NSLog(@"syncDropbox.txt exist!");
        [fileName writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error: nil];
    }
}

- (void)createItemArray{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSString *document=[NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    muoPath =[document stringByAppendingPathComponent:@"Muo"];
    itemArray = [[fileManager contentsOfDirectoryAtPath:muoPath error:&error]mutableCopy];
    for (NSString* item in itemArray) {
//        if (![[[item substringFromIndex: [item length] - 2] uppercaseString]isEqualToString:@"MD"]){
//            [itemArray removeObject:item];
//        }
        NSLog(@"createItemArray %@",item);
    }
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self createItemArray];
    for (NSString* item in itemArray) {
        NSLog(@"viewDidLoad %@",item);}
    // self.clearsSelectionOnViewWillAppear = NO;
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    self.itemArray = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	return YES;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.itemArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.text = [itemArray objectAtIndex:indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath*)indexPath
{
    if(editingStyle == UITableViewCellEditingStyleDelete)
    {
        
        for (NSString *xxd in itemArray) {
            NSLog(@"%@",xxd);
        }
        NSString *mkFileName = [itemArray objectAtIndex:indexPath.row];
        NSLog(@"mkFileName NO.%i is %@",indexPath.row, mkFileName);
        [self.itemArray removeObjectAtIndex:indexPath.row];
        [self deleteFile:mkFileName];
        //[self syncDropboxFile:mkFileName];
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.delegate controller:self editTextContent:[itemArray objectAtIndex:indexPath.row]];
    NSLog(@"fire");
//    ViewController *mainViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"mainViewController"];
//    mainViewController.markdownTextView.text = [itemArray objectAtIndex:indexPath.row];
//    NSLog(@"%@", [itemArray objectAtIndex:indexPath.row]);
}

@end
