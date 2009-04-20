// -*-  Mode:ObjC; c-basic-offset:4; tab-width:8; indent-tabs-mode:nil -*-
/*
  CashFlow for iPhone/iPod touch

  Copyright (c) 2008, Takuya Murakami, All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  1. Redistributions of source code must retain the above copyright notice,
  this list of conditions and the following disclaimer. 

  2. Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in the
  documentation and/or other materials provided with the distribution. 

  3. Neither the name of the project nor the names of its contributors
  may be used to endorse or promote products derived from this software
  without specific prior written permission. 

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" ANDY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR
  CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL,
  EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
  PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR
  PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
  LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
  NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
  SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/


#import "TransactionListVC.h"
#import "AppDelegate.h"
#import "Transaction.h"
#import "InfoVC.h"
#import "EditValueVC.h"
#import "ReportVC.h"

@implementation TransactionListViewController

@synthesize tableView;
@synthesize asset;

- (id)init
{
    self = [super initWithNibName:@"TransactionListView" bundle:nil];
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    // title 設定
    //self.title = NSLocalizedString(@"Transactions", @"");
    self.title = asset.name;
	
    // "+" ボタンを追加
    UIBarButtonItem *plusButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                      target:self
                                      action:@selector(addTransaction)];
	
    self.navigationItem.rightBarButtonItem = plusButton;
    [plusButton release];
	
    // Edit ボタンを追加
    // TBD
    //self.navigationItem.leftBarButtonItem = [self editButtonItem];
	
    // 下位 View を作っておく
    if (transactionView == nil) {
        transactionView = [[TransactionViewController alloc] init];
    }
    transactionView.asset = asset;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)dealloc {
    [transactionView release];
    [tableView release];

    [super dealloc];
}


- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self updateBalance];
	
    [self.tableView reloadData]; //### Reload data...
}

- (void)updateBalance
{
    double lastBalance = [asset lastBalance];
    NSString *bstr = [DataModel currencyString:lastBalance];

#if 0
    UILabel *tableTitle = (UILabel *)[self.tableView tableHeaderView];
    tableTitle.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Balance", @""), bstr];
#endif
	
    barBalanceLabel.title = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Balance", @""), bstr];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
}

- (void)viewDidDisappear:(BOOL)animated {
}

- (IBAction)showHelp:(id)sender
{
    InfoVC *v = [[[InfoVC alloc] init] autorelease];
    [self.navigationController pushViewController:v animated:YES];
}


#pragma mark TableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [asset entryCount] + 1;
}

// 指定セル位置に該当する entry Index を返す
- (int)entryIndexWithIndexPath:(NSIndexPath *)indexPath
{
    return [asset entryCount] - indexPath.row - 1;
}

// 指定セル位置の Entry を返す
- (AssetEntry *)entryWithIndexPath:(NSIndexPath *)indexPath
{
    int idx = [self entryIndexWithIndexPath:indexPath];

    if (idx < 0) {
        return nil;  // initial balance
    } 
    AssetEntry *e = [asset entryAt:idx];
    return e;
}

//
// セルの内容を返す
//
#define TAG_DESC 1
#define TAG_DATE 2
#define TAG_VALUE 3
#define TAG_BALANCE 4

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
	
    AssetEntry *e = [self entryWithIndexPath:indexPath];
    if (e) {
        cell = [self _entryCell:e];
    } else {
        cell = [self initialBalanceCell];
    }

    return cell;
}

// Entry セルの生成 (private)
- (UITableViewCell *)_entryCell:(AssetEntry *)e
{
    NSString *cellid = @"transactionCell";

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellid];
    UILabel *descLabel, *dateLabel, *valueLabel, *balanceLabel;

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellid] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        //cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
        descLabel = [[[UILabel alloc] initWithFrame:CGRectMake(5, 0, 220, 24)] autorelease];
        descLabel.tag = TAG_DESC;
        descLabel.font = [UIFont systemFontOfSize: 18.0];
        descLabel.textColor = [UIColor blackColor];
        descLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:descLabel];
		
        valueLabel = [[[UILabel alloc] initWithFrame:CGRectMake(190, 0, 120, 24)] autorelease];
        valueLabel.tag = TAG_VALUE;
        valueLabel.font = [UIFont systemFontOfSize: 18.0];
        valueLabel.textAlignment = UITextAlignmentRight;
        valueLabel.textColor = [UIColor blueColor];
        valueLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:valueLabel];
		
        dateLabel = [[[UILabel alloc] initWithFrame:CGRectMake(5, 24, 160, 20)] autorelease];
        dateLabel.tag = TAG_DATE;
        dateLabel.font = [UIFont systemFontOfSize: 14.0];
        dateLabel.textColor = [UIColor grayColor];
        dateLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:dateLabel];
		
        balanceLabel = [[[UILabel alloc] initWithFrame:CGRectMake(150, 24, 160, 20)] autorelease];
        balanceLabel.tag = TAG_BALANCE;
        balanceLabel.font = [UIFont systemFontOfSize: 14.0];
        balanceLabel.textAlignment = UITextAlignmentRight;
        balanceLabel.textColor = [UIColor grayColor];
        balanceLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:balanceLabel];
    } else {
        descLabel = (UILabel *)[cell.contentView viewWithTag:TAG_DESC];
        dateLabel = (UILabel *)[cell.contentView viewWithTag:TAG_DATE];
        valueLabel = (UILabel *)[cell.contentView viewWithTag:TAG_VALUE];
        balanceLabel = (UILabel *)[cell.contentView viewWithTag:TAG_BALANCE];
    }

    descLabel.text = e.transaction.description;
    dateLabel.text = [[DataModel dateFormatter] stringFromDate:e.transaction.date];
	
    double v = e.value;
    if (v >= 0) {
        valueLabel.textColor = [UIColor blueColor];
    } else {
        v = -v;
        valueLabel.textColor = [UIColor redColor];
    }
    valueLabel.text = [DataModel currencyString:v];
    balanceLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Balance", @""), [DataModel currencyString:e.balance]];
	
    return cell;
}

// 初期残高セルの生成 (private)
- (UITableViewCell *)initialBalanceCell
{
    NSString *cellid = @"initialBalanceCell";

    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:cellid];
    UILabel *descLabel, *balanceLabel;

    if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:cellid] autorelease];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
		
        descLabel = [[[UILabel alloc] initWithFrame:CGRectMake(5, 0, 190, 24)] autorelease];
        descLabel.font = [UIFont systemFontOfSize: 18.0];
        descLabel.textColor = [UIColor blackColor];
        descLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        descLabel.text = NSLocalizedString(@"Initial Balance", @"");
        [cell.contentView addSubview:descLabel];

        balanceLabel = [[[UILabel alloc] initWithFrame:CGRectMake(150, 24, 160, 20)] autorelease];
        balanceLabel.tag = TAG_BALANCE;
        balanceLabel.font = [UIFont systemFontOfSize: 14.0];
        balanceLabel.textAlignment = UITextAlignmentRight;
        balanceLabel.textColor = [UIColor grayColor];
        balanceLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [cell.contentView addSubview:balanceLabel];
    } else {
        balanceLabel = (UILabel *)[cell.contentView viewWithTag:TAG_BALANCE];
    }

    balanceLabel.text = [NSString stringWithFormat:@"%@ %@", NSLocalizedString(@"Balance", @""), 
                                  [DataModel currencyString:asset.initialBalance]];

    return cell;
}

//
// セルをクリックしたときの処理
//
- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tv deselectRowAtIndexPath:indexPath animated:NO];
	
    int idx = [self entryIndexWithIndexPath:indexPath];
    if (idx < 0) {
        // initial balance cell
        EditValueViewController *v = [[[EditValueViewController alloc] init] autorelease];
        v.listener = self;
        v.value = asset.initialBalance;

        [self.navigationController pushViewController:v animated:YES];
    } else {
        // transaction view を表示
        [transactionView setTransactionIndex:idx];
        [self.navigationController pushViewController:transactionView animated:YES];
    }
}

// 初期残高変更処理
- (void)editValueViewChanged:(EditValueViewController *)vc
{
    asset.initialBalance = vc.value;
    [asset updateInitialBalance];
    [asset rebuild];
}

// 新規トランザクション追加
- (void)addTransaction
{
    [transactionView setTransactionIndex:-1];
    [self.navigationController pushViewController:transactionView animated:YES];
}

// Editボタン処理
- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
	
    // tableView に通知
    [tableView setEditing:editing animated:animated];
	
    if (editing) {
        self.navigationItem.rightBarButtonItem.enabled = NO;
    } else {
        self.navigationItem.rightBarButtonItem.enabled = YES;
    }
}

// 編集スタイルを返す
- (UITableViewCellEditingStyle)tableView:(UITableView*)tv editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath
{
    int entryIndex = [self entryIndexWithIndexPath:indexPath];
    if (entryIndex < 0) {
        return UITableViewCellEditingStyleNone;
    } 
    return UITableViewCellEditingStyleDelete;
}

// 削除処理
- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath*)indexPath
{
    int entryIndex = [self entryIndexWithIndexPath:indexPath];

    if (entryIndex < 0) {
        // initial balance cell : do not delete!
        return;
    }
	
    if (style == UITableViewCellEditingStyleDelete) {
        [asset deleteEntryAt:entryIndex];
	
        [tv deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
        [self updateBalance];
        [self.tableView reloadData];
    }
}

// action sheet
- (void)doAction:(id)sender
{
    UIActionSheet *as = [[UIActionSheet alloc] initWithTitle:@"" delegate:self 
                                               cancelButtonTitle:NSLocalizedString(@"Cancel", @"")
                                               destructiveButtonTitle:nil otherButtonTitles:
                                                   NSLocalizedString(@"Weekly Report", @""),
                                               NSLocalizedString(@"Monthly Report", @""),
                                               NSLocalizedString(@"Export", @""),
                                               //NSLocalizedString(@"Info", @""),
                                               //NSLocalizedString(@"Delete Transactions", @""),
                                               nil];
    [as showInView:[self view]];
    [as release];
}

- (void)actionSheet:(UIActionSheet*)as clickedButtonAtIndex:(NSInteger)buttonIndex
{
    ReportViewController *reportVC;
    ExportVC *exportVC;

    switch (buttonIndex) {
    case 0:
    case 1:
        reportVC = [[[ReportViewController alloc] init] autorelease];
        if (buttonIndex == 0) {
            reportVC.title = NSLocalizedString(@"Weekly Report", @"");
            [reportVC generateReport:REPORT_WEEKLY asset:asset];
        } else {
            reportVC.title = NSLocalizedString(@"Monthly Report", @"");
            [reportVC generateReport:REPORT_MONTHLY asset:asset];
        }
        [self.navigationController pushViewController:reportVC animated:YES];
        break;
			
    case 2:
        exportVC = [[[ExportVC alloc] initWithAsset:asset] autorelease];
        [self.navigationController pushViewController:exportVC animated:YES];
        break;
    }
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end