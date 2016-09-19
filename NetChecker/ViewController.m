//
//  ViewController.m
//  NetChecker
//
//  Created by 徐凌峰 on 16/9/12.
//  Copyright © 2016年 wangmi. All rights reserved.
//

#import "ViewController.h"
#import "CheckViewController.h"
#import "Common.h"

#define titles @[@"本机信息", @"ping", @"路由轨迹", @"DNS解析"]

@interface ViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *mainTableView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.edgesForExtendedLayout = UIRectEdgeNone;
    
    [self.view addSubview:self.mainTableView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UITableView *)mainTableView {
    if (!_mainTableView) {
        _mainTableView = [[UITableView alloc] initWithFrame:self.view.bounds style:UITableViewStyleGrouped];
        [_mainTableView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];
        _mainTableView.delegate = self;
        _mainTableView.dataSource = self;
        [_mainTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    }
    
    return _mainTableView;
}

#pragma mark -- delegate && datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell"];
    
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = titles[indexPath.row];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.row) {
        case 0:
        {
            LocalInfoViewController *vc = [LocalInfoViewController new];
            vc.title = titles[indexPath.row];
            vc.netCheckType = NetCheckTypeLocal;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 1:
        {
            PingViewController *vc = [PingViewController new];
            vc.title = @"ping";
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 2:
        {
            CheckViewController *vc = [CheckViewController new];
            vc.title = titles[indexPath.row];
            vc.netCheckType = NetCheckTypeTraceroute;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
        case 3:
        {
            CheckViewController *vc = [CheckViewController new];
            vc.title = titles[indexPath.row];
            vc.netCheckType = NetCheckTypeDNS;
            [self.navigationController pushViewController:vc animated:YES];
        }
            break;
            
        default:
            break;
    }    
}

//分割线左对齐
-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Remove seperator inset
    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
        [cell setSeparatorInset:UIEdgeInsetsZero];
    }
    // Prevent the cell from inheriting the Table View's margin settings
    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
        [cell setPreservesSuperviewLayoutMargins:NO];
    }
    // Explictly set your cell's layout margins
    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
        [cell setLayoutMargins:UIEdgeInsetsZero];
    }
}

//假装没header
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.0001;
}

@end
