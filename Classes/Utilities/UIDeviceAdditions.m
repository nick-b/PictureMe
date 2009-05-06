//
//  UIDeviceAdditions.m
//  Whiteboard
//
//  Created by Jeremy Collins on 2/23/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "UIDeviceAdditions.h"

#include <sys/sysctl.h>  
#include <mach/mach.h>

@implementation UIDevice (Additions)

- (double)availableMemory {
	vm_statistics_data_t vmStats;
	mach_msg_type_number_t infoCount = HOST_VM_INFO_COUNT;
	kern_return_t kernReturn = host_statistics(mach_host_self(), HOST_VM_INFO, (host_info_t)&vmStats, &infoCount);
	
	if(kernReturn != KERN_SUCCESS) {
		return NSNotFound;
	}
	
	return ((vm_page_size * vmStats.free_count) / 1024.0) / 1024.0;
}

@end