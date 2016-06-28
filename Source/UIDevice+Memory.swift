//
//  UIDevice+Memory.swift
//  DeviceKit
//
//  Created by Ling Wang on 4/11/16.
//
//

import UIKit
import Darwin.sys.sysctl

public extension UIDevice {
    public func memoryInfo() -> String {
        let bcFormatter = NSByteCountFormatter()
        bcFormatter.countStyle = .Memory
        // FIXME: workaround for "Expression was too complex to be solved in reasonable time; consider breaking up the expression into distinct sub-expressions"
        var info = "Memory Status:\n" +
            "Total: \(bcFormatter.stringFromByteCount(numericCast(totalMemory)))\n" +
            "User: \(bcFormatter.stringFromByteCount(numericCast(userMemory)))\n" +
            "Virtual: \(bcFormatter.stringFromByteCount(numericCast(virtualMemory)))\n" +
            "Resident: \(bcFormatter.stringFromByteCount(numericCast(residentMemory)))\n"
        info +=
            "Page Size: \(getPageSizeAndVMStatistics().0)\n" +
            "Free: \(bcFormatter.stringFromByteCount(numericCast(freeMemory)))\n" +
            "Active: \(bcFormatter.stringFromByteCount(numericCast(activeMemory)))\n" +
            "Inactive: \(bcFormatter.stringFromByteCount(numericCast(inactiveMemory)))\n" +
            "Wired: \(bcFormatter.stringFromByteCount(numericCast(wiredMemory)))\n" +
            "Purgeable: \(bcFormatter.stringFromByteCount(numericCast(purgeableMemory)))"
        return info
    }
}

// MARK: sysctl
public extension UIDevice {
    private func getSysInfo(name: Int32) -> UInt64 {
        var mib = [CTL_HW, name]
        var size = 0
        sysctl(&mib, 2, nil, &size, nil, 0)        
        let resultPointer = UnsafeMutablePointer<Void>.alloc(size)
        sysctl(&mib, 2, resultPointer, &size, nil, 0)
        let result: UInt64
        switch size {
        case 8:
            result = numericCast(UnsafeMutablePointer<UInt64>(resultPointer).memory)
            
        case 4:
            result = numericCast(UnsafeMutablePointer<UInt32>(resultPointer).memory)
            
        default:
            result = 0
        }
        resultPointer.dealloc(size)
        return result
    }
    
    public var totalMemory: UInt64 {
        return getSysInfo(HW_PHYSMEM)
    }
    
    public var userMemory: UInt64 {
        return getSysInfo(HW_USERMEM)
    }
}

// MARK: task_info
public extension UIDevice {
    private func getTaskInfo() -> task_basic_info {
        var info = task_basic_info()
        var infoSize = mach_msg_type_number_t(sizeof(task_basic_info) / sizeof(natural_t))
        withUnsafeMutablePointer(&info) { (infoPointer) in
            let result = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), task_info_t(infoPointer), &infoSize)
            if result != KERN_SUCCESS {
                print("Failed to get task info: \(result)")
            }
        }
        return info
    }
    
    public var residentMemory: UInt64 {
        return numericCast(getTaskInfo().resident_size)
    }
    
    public var virtualMemory: UInt64 {
        return numericCast(getTaskInfo().virtual_size)
    }
}

// MARK: host_page_size & host_statistics
public extension UIDevice {
    private func getPageSizeAndVMStatistics() -> (vm_size_t, vm_statistics) {
        let hostPort = mach_host_self()
        var pageSize: vm_size_t = 0
        let result = host_page_size(hostPort, &pageSize)
        if result != KERN_SUCCESS {
            print("Failed to get page size: \(result)")
        }
        
        var info = vm_statistics()
        var infoSize = mach_msg_type_number_t(sizeof(vm_statistics) / sizeof(natural_t))
        withUnsafeMutablePointer(&info) { (infoPointer) in
            let result = host_statistics(hostPort, HOST_VM_INFO, host_info_t(infoPointer), &infoSize)
            if result != KERN_SUCCESS {
                print("Failed to get vm statistics: \(result)")
            }
        }
        return (pageSize, info)
    }
    
    public var freeMemory: UInt64 {
        let (pageSize, vmStatistics) = getPageSizeAndVMStatistics()
        return UInt64(vmStatistics.free_count) * UInt64(pageSize)
    }
    
    public var activeMemory: UInt64 {
        let (pageSize, vmStatistics) = getPageSizeAndVMStatistics()
        return UInt64(vmStatistics.active_count) * UInt64(pageSize)
    }
    
    public var inactiveMemory: UInt64 {
        let (pageSize, vmStatistics) = getPageSizeAndVMStatistics()
        return UInt64(vmStatistics.inactive_count) * UInt64(pageSize)
    }
    
    public var wiredMemory: UInt64 {
        let (pageSize, vmStatistics) = getPageSizeAndVMStatistics()
        return UInt64(vmStatistics.wire_count) * UInt64(pageSize)
    }
    
    public var purgeableMemory: UInt64 {
        let (pageSize, vmStatistics) = getPageSizeAndVMStatistics()
        return UInt64(vmStatistics.purgeable_count) * UInt64(pageSize)
    }
}
