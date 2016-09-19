//
//  CheckViewController.m
//  NetChecker
//
//  Created by 徐凌峰 on 16/9/12.
//  Copyright © 2016年 wangmi. All rights reserved.
//

#import "CheckViewController.h"

@interface CheckViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, LDNetDiagnoServiceDelegate, UITextViewDelegate>

@property (nonatomic, strong) UITableView *mainTableView;

@property (nonatomic, strong) UITextView *textView ;

@property (nonatomic, strong) UITextField *textField;

@property (nonatomic, strong) LDNetDiagnoService *netDiagnoService;

@property (nonatomic, copy) NSString *logInfo;

@property (nonatomic, strong) UIButton *button;

@end

@implementation CheckViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    [self setupRightButtonItem];
    
    [self.view addSubview:self.mainTableView];
    
    _netDiagnoService = [[LDNetDiagnoService alloc] initWithAppCode:@"test"
                                                            appName:@"NetChecker"
                                                         appVersion:nil
                                                             userID:nil
                                                           deviceID:nil
                                                            dormain:_textField.text
                                                        carrierName:nil
                                                     ISOCountryCode:nil
                                                  MobileCountryCode:nil
                                                      MobileNetCode:nil];
    _netDiagnoService.delegate = self;
    _logInfo = @"";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)setupRightButtonItem {
    self.button = [UIButton buttonWithType:UIButtonTypeSystem];
    self.button.frame = CGRectMake(0, 0, 40, 40);
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
        _textView.delegate = self;
        _textView.editable = NO;
    }
    
    return _textView;
}

- (UITextField *)textField {
    if (!_textField) {
        _textField = [UITextField new];
        _textField.placeholder = @"Domain or IP address";
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

#pragma mark -- textViewDelegate

- (void)textViewDidChange:(UITextView *)textView {
    [textView scrollRangeToVisible:NSMakeRange(self.textView.text.length, 0)];
}

#pragma mark -- click

- (void)click:(UIButton *)button {
    [self.textField resignFirstResponder];
    self.netDiagnoService.dormain = self.textField.text;
    
    switch (self.netCheckType) {
        case NetCheckTypeTraceroute:
            [_netDiagnoService traceroute];
            break;
        case NetCheckTypeDNS:
            [_netDiagnoService DNSAnalysis];
            break;
            
        default:
            break;
    }
}

#pragma mark NetDiagnosisDelegate

- (void)netDiagnosisStepInfo:(NSString *)stepInfo
{
    NSLog(@"%@", stepInfo);
    self.logInfo = [self.logInfo stringByAppendingString:stepInfo];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.textView.text = self.logInfo;
    });
}

- (void)netDiagnosisDidEnd:(NSString *)allLogInfo;
{
    NSLog(@"logInfo>>>>>\n%@", allLogInfo);
    //可以保存到文件，也可以通过邮件发送回来
    dispatch_async(dispatch_get_main_queue(), ^{
        
    });
}

@end
