//
//  main.m
//  TesteSQLite3
//
//  Created by Carla de Oliveira Camargo on 28/05/20.
//  Copyright © 2020 Carla de Oliveira Camargo. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    NSString * appDelegateClassName;
    @autoreleasepool {
        // Setup code that might create autoreleased objects goes here.
        appDelegateClassName = NSStringFromClass([AppDelegate class]);
    }
    return UIApplicationMain(argc, argv, nil, appDelegateClassName);
}
