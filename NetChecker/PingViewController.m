//
//  PingViewController.m
//  NetChecker
//
//  Created by 徐凌峰 on 16/9/13.
//  Copyright © 2016年 wangmi. All rights reserved.
//

#import "PingViewController.h"
#import "Common.h"
#import "LDNetGetAddress.h"

@interface PingViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

@property (nonatomic, strong) UITextField        *textField;
@property (nonatomic, strong) UITextView    *textView;
@property (nonatomic, strong) STDPingServices    *pingServices;
@property (nonatomic, strong) UITableView       *mainTableView;
@property (nonatomic, strong) UIButton          *button;
@property (nonatomic, assign) NETWORK_TYPE curNetType;

@end

@implementation PingViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupRightButtonItem];
    
    [self.view addSubview:self.mainTableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupRightButtonItem {
    self.button = [UIButton buttonWithType:UIButtonTypeSystem];
    self.button.frame = CGRectMake(0, 0, 40, 40);
    self.button.tag = 10001;
    [self.button setTitle:@"start" forState:UIControlStateNormal];
    [self.button addTarget:self action:@selector(click:) forControlEvents:UIControlEventTouchUpInside];
    
    UIBarButtonItem *barbuttonItem = [[UIBarButtonItem alloc] initWithCustomView:self.button];
    
    self.navigationItem.rightBarButtonItem = barbuttonItem;
}

- (UITableView *)mainTableView {
    if (!_mainTableView) {
        _mainTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        [_mainTableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        _mainTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _mainTableView.allowsSelection = NO;
        _mainTableView.scrollEnabled = NO;
        _mainTableView.delegate = self;
        _mainTableView.dataSource = self;
        [_mainTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    }
    
    return _mainTableView;
}

- (UITextView *)textView {
    if (!_textView) {
        _textView = [UITextView new];
        _textView.editable = NO;
    }
    
    return _textView;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [UITextField new];
        _textField.placeholder = @"域名或者IP地址";
        _textField.text = @"www.baidu.com";
        _textField.font = [UIFont systemFontOfSize:14];
        _textField.returnKeyType = UIReturnKeyDone;
        _textField.borderStyle = UITextBorderStyleRoundedRect;
        _textField.delegate = self;
    }
    
    return _textField;
}

#pragma mark -- delegate && datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    if (indexPath.section == 0) {
        [cell.contentView addSubview:self.textField];
        
        UILabel *label = [UILabel new];
        label.text = @"添加到服务器列表";
        label.font = [UIFont systemFontOfSize:14];
        [cell.contentView addSubview:label];
        [label setSingleLineAutoResizeWithMaxWidth:200];
        
        self.textField.sd_layout.centerXEqualToView(cell.contentView).topSpaceToView(cell.contentView, 10).widthRatioToView(cell.contentView, 0.7).heightIs(20);
        label.sd_layout.leftEqualToView(self.textField).topSpaceToView(self.textField, 10).bottomSpaceToView(cell.contentView, 10);
    }
    else {
        [cell.contentView addSubview:self.textView];
        
        self.textView.sd_layout.widthRatioToView(cell.contentView, 1).heightRatioToView(cell.contentView, 1);
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0) {
        return 80;
    }
    else {
        return self.mainTableView.height - 30*2 - 80;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.0001;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    NSString *title;
    if (section == 0) {
        title = @"服务器";
    }
    else {
        title = @"输出信息:";
    }
    
    return title;
}

#pragma mark -- textFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark -- click

- (void)click:(UIButton *)button {
    [self.textField resignFirstResponder];
    
    self.curNetType = [LDNetGetAddress getNetworkTypeFromStatusBar];
    if (self.curNetType == 0) {
        self.textView.text = @"\n\tNot networking";
        return;
    }
    
    if (button.tag == 10001) {
        __weak typeof(self)weakSelf = self;
        [button setTitle:@"Stop" forState:UIControlStateNormal];
        button.tag = 10002;
        self.pingServices = [STDPingServices startPingAddress:self.textField.text callbackHandler:^(STDPingItem *pingItem, NSArray *pingItems) {
            if (pingItem.status != STDPingStatusFinished) {
                weakSelf.textView.text = [[weakSelf.textView.text stringByAppendingString:@"\n"] stringByAppendingString:pingItem.description];
                [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length, 0)];
            } else {
                weakSelf.textView.text = [[weakSelf.textView.text stringByAppendingString:@"\n"] stringByAppendingString:[STDPingItem statisticsWithPingItems:pingItems]];
                [self.textView scrollRangeToVisible:NSMakeRange(self.textView.text.length, 0)];
                [button setTitle:@"start" forState:UIControlStateNormal];
                button.tag = 10001;
                weakSelf.pingServices = nil;
            }
        }];
    } else {
        [self.pingServices cancel];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [self.pingServices cancel];
    self.pingServices = nil;
}

@end
