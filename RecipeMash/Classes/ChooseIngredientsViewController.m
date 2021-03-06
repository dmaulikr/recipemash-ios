//
//  ChooseIngredientsViewController.m
//  RecipeMash
//
//  Created by Sidwyn Koh on 10/11/13.
//  Copyright (c) 2013 Sidwyn Koh. All rights reserved.
//

#import "ChooseIngredientsViewController.h"
#import "VTPG_Common.h"
#import <AFNetworking/AFNetworking.h>
#import "RecipeListViewController.h"
#import "FridgeViewController.h"
#import "NSString+Levenshtein.h"

@interface ChooseIngredientsViewController ()

@property (nonatomic, retain) NSMutableArray *listOfSelectedIngredientsIndices;

@end

@implementation ChooseIngredientsViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"Cell"];

    self.title = @"Choose Ingredients";
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc] initWithTitle:@"Back" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.topItem.backBarButtonItem = backButton;

    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Add" style:UIBarButtonItemStylePlain target:self action:@selector(makeRecipes)];
    self.navigationItem.rightBarButtonItem = nextButton;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithTitle:@"Cancel" style:UIBarButtonItemStylePlain target:self action:@selector(close)];
    self.navigationItem.leftBarButtonItem = cancelButton;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)close
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)makeRecipes
{

    [self dismissViewControllerAnimated:YES completion:^(void) {
        
        NSMutableArray *toAddArray = [NSMutableArray array];
        for (UITableViewCell *cell in self.tableView.visibleCells) {
            if (cell.accessoryType == UITableViewCellAccessoryCheckmark && cell.textLabel.text.length > 0) {
                [toAddArray addObject:[NSString stringWithFormat:@"%@", cell.textLabel.text]];
            }
        }
        
        // Remove duplicates in this adding array
        [toAddArray setArray:[[NSSet setWithArray:toAddArray] allObjects]];
        
        // Prevent addition of a duplicate
        NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:@"listOfSavedIngredients"];
        NSMutableArray *listOfSavedIngredients = [NSMutableArray arrayWithArray:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
        
        NSString *myUserId = [[NSUserDefaults standardUserDefaults] objectForKey:@"facebookUserId"];
        for (NSString *eachIngredient in toAddArray) {
            if (![listOfSavedIngredients containsObject:eachIngredient]) {
                [listOfSavedIngredients addObject:eachIngredient];
                NSString *concatenate = [NSString stringWithFormat:@"http://smsa.berkeley.edu/hackathon/insert.php?name=%@&quantity=1&id=%@", eachIngredient, myUserId];
                concatenate = [concatenate stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
                LOG_EXPR(concatenate);
                AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
                [manager GET:concatenate parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
                    // Update server
                    }
                 failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                }];
            }
        }

        NSData *data2 = [NSKeyedArchiver archivedDataWithRootObject:listOfSavedIngredients];
        [[NSUserDefaults standardUserDefaults] setObject:data2 forKey:@"listOfSavedIngredients"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        FridgeViewController *fvc = [[FridgeViewController alloc] init];
        [self.parentController.navigationController pushViewController:fvc animated:YES];
    }];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if (self.listOfIngredients) {
        return self.listOfIngredients.count;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    // Configure the cell...
    NSString *ingredient = [self.listOfIngredients objectAtIndex:indexPath.row];
    cell.textLabel.text = ingredient;
    
    cell.textLabel.textColor = UIColorFromRGB(0x1986fb);
    cell.accessoryType = UITableViewCellAccessoryCheckmark;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if ([[tableView cellForRowAtIndexPath:indexPath] accessoryType ]!= UITableViewCellAccessoryCheckmark) {
        // If it's not on, select it
        [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryCheckmark];
        [self.listOfSelectedIngredientsIndices addObject:indexPath];
        UITableViewCell *theCell = [tableView cellForRowAtIndexPath:indexPath];
        theCell.textLabel.textColor = UIColorFromRGB(0x1986fb);
    }
    else {
        // If it's on, remove it
        [[tableView cellForRowAtIndexPath:indexPath] setAccessoryType:UITableViewCellAccessoryNone];
        [self.listOfSelectedIngredientsIndices removeObject:indexPath];
        [[[tableView cellForRowAtIndexPath:indexPath] textLabel] setTextColor:[UIColor blackColor]];
    }
}

// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}


/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
