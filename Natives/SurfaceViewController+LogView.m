#import "SurfaceViewController.h"

extern UIWindow* currentWindow();

@interface LogDelegate : NSObject
@end

@interface LogDelegate()<UITableViewDataSource, UITableViewDelegate>
@end

static NSMutableArray* logLines;

@implementation LogDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return logLines.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];

    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.backgroundColor = UIColor.clearColor;
        //cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [UIFont fontWithName:@"Menlo-Regular" size:16];
        cell.textLabel.textColor = UIColor.whiteColor;
    }
    cell.textLabel.text = logLines[indexPath.row];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:NO];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    NSString *line = cell.textLabel.text;
    if (line.length == 0 || [line isEqualToString:@"\n"]) {
        return;
    }

    SurfaceViewController *vc = (id)currentWindow().rootViewController;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:line preferredStyle:UIAlertControllerStyleActionSheet];
    alert.popoverPresentationController.sourceView = cell;
    alert.popoverPresentationController.sourceRect = cell.bounds;
    UIAlertAction *share = [UIAlertAction actionWithTitle:NSLocalizedString(NSLocalizedString(@"Share", nil), nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UIView *navigationBar = vc.logOutputView.subviews[0];
        UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:@[line] applicationActivities:nil];
        activityVC.popoverPresentationController.sourceView = navigationBar;
        activityVC.popoverPresentationController.sourceRect = navigationBar.bounds;
        [vc presentViewController:activityVC animated:YES completion:nil];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", nil) style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:share];
    [alert addAction:cancel];
    [vc presentViewController:alert animated:YES completion:nil];
}

@end

@implementation SurfaceViewController(LogView)

static LogDelegate* logDelegate;
static int logCharPerLine;

- (void)initCategory_LogView {
    logLines = NSMutableArray.new;
    logCharPerLine = self.view.frame.size.width / 10;

    self.logOutputView = [[UIView alloc] initWithFrame:CGRectOffset(self.view.frame, 0, self.view.frame.size.height)];
    self.logOutputView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    self.logOutputView.hidden = YES;

    UINavigationItem *navigationItem = [[UINavigationItem alloc] init];
    navigationItem.rightBarButtonItems = @[
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemStop
            target:self action:@selector(actionToggleLogOutput)],
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash
            target:self action:@selector(actionClearLogOutput)]
    ];
    UINavigationBar* navigationBar = [[UINavigationBar alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 44)];
    navigationBar.items = @[navigationItem];
    navigationBar.topItem.title = NSLocalizedString(@"game.menu.log_output", nil);
    [self.logOutputView addSubview:navigationBar];
    canAppendToLog = YES;
    [self actionStartStopLogOutput];

    self.logTableView = [[UITableView alloc] initWithFrame:
        CGRectMake(0, navigationBar.frame.size.height, self.view.frame.size.width, self.view.frame.size.height - navigationBar.frame.size.height)];
    logDelegate = [[LogDelegate alloc] init];
    //self.logTableView.allowsSelection = NO;
    self.logTableView.backgroundColor = UIColor.clearColor;
    self.logTableView.dataSource = logDelegate;
    self.logTableView.delegate = logDelegate;
    self.logTableView.layoutMargins = UIEdgeInsetsZero;
    self.logTableView.rowHeight = 20;
    self.logTableView.separatorInset = UIEdgeInsetsZero;
    self.logTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.logOutputView addSubview:self.logTableView];
    [self.rootView addSubview:self.logOutputView];

    //canAppendToLog = YES;
}

- (void)actionClearLogOutput {
    [logLines removeAllObjects];
    [self.logTableView reloadData];
}

- (void)actionStartStopLogOutput {
    canAppendToLog = !canAppendToLog;
    UINavigationItem* item = ((UINavigationBar *)self.logOutputView.subviews[0]).items[0];
    item.leftBarButtonItem =
        [[UIBarButtonItem alloc] initWithBarButtonSystemItem:
            canAppendToLog ? UIBarButtonSystemItemPause : UIBarButtonSystemItemPlay
        target:self action:@selector(actionStartStopLogOutput)];
}

- (void)actionToggleLogOutput {
    UIViewAnimationOptions opt = self.logOutputView.hidden ? UIViewAnimationOptionCurveEaseOut : UIViewAnimationOptionCurveEaseIn;
    [UIView transitionWithView:self.logOutputView duration:0.4 options:UIViewAnimationOptionCurveEaseOut animations:^(void){
        CGRect frame = self.logOutputView.frame;
        frame.origin.y = self.logOutputView.hidden ? 0 : frame.size.height;
        self.logOutputView.hidden = NO;
        self.logOutputView.frame = frame;
    } completion: ^(BOOL finished) {
        self.logOutputView.hidden = self.logOutputView.frame.origin.y != 0;
    }];
}

+ (void)_appendToLog:(NSString *)line {
    SurfaceViewController *instance = (id)currentWindow().rootViewController;

    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:logLines.count inSection:0];
    [logLines addObject:line];
    [instance.logTableView beginUpdates];
    [instance.logTableView
        insertRowsAtIndexPaths:@[indexPath]
        withRowAnimation:UITableViewRowAnimationNone];
    [instance.logTableView endUpdates];

    [instance.logTableView 
        scrollToRowAtIndexPath:indexPath
        atScrollPosition:UITableViewScrollPositionBottom animated:NO];
}

+ (void)appendToLog:(NSString *)line {
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self _appendToLog:line];
    });
}

@end
