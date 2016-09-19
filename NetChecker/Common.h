//
//  Common.h
//  NetChecker
//
//  Created by 徐凌峰 on 16/9/12.
//  Copyright © 2016年 wangmi. All rights reserved.
//

#ifndef Common_h
#define Common_h

typedef NS_ENUM(NSInteger, LFNetCheckType) {
    NetCheckTypePing = 0,
    NetCheckTypeTraceroute = 1,
    NetCheckTypeDNS = 2,
    NetCheckTypeLocal = 3,
};

#import "SDAutoLayout.h"
#import "LDNetDiagnoService.h"
#import "STDPingServices.h"
#import "PingViewController.h"
#import "LocalInfoViewController.h"

#endif /* Common_h */
