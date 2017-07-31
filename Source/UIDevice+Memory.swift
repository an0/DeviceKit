//
//  UIDevice+Memory.swift
//  DeviceKit
//
//  Created by Ling Wang on 4/11/16.
//
//

import UIKit

@objc
public extension UIDevice {
  
  public func memoryInfo() -> String {
    let bcFormatter = ByteCountFormatter()
    bcFormatter.countStyle = .memory
    // FIXME: workaround for "Expression was too complex to be solved in reasonable time; consider breaking up the expression into distinct sub-expressions"
    var info = "Memory Status:\n" +
      "Total: \(bcFormatter.string(fromByteCount: numericCast(totalMemory)))\n" +
      "User: \(bcFormatter.string(fromByteCount: numericCast(userMemory)))\n" +
      "Virtual: \(bcFormatter.string(fromByteCount: numericCast(virtualMemory)))\n" +
      "Resident: \(bcFormatter.string(fromByteCount: numericCast(residentMemory)))\n"
    info +=
      "Page Size: \(getPageSizeAndVMStatistics().0)\n" +
      "Free: \(bcFormatter.string(fromByteCount: numericCast(freeMemory)))\n" +
      "Active: \(bcFormatter.string(fromByteCount: numericCast(activeMemory)))\n" +
      "Inactive: \(bcFormatter.string(fromByteCount: numericCast(inactiveMemory)))\n" +
      "Wired: \(bcFormatter.string(fromByteCount: numericCast(wiredMemory)))\n" +
      "Purgeable: \(bcFormatter.string(fromByteCount: numericCast(purgeableMemory)))"
    return info
  }
 
  public var totalMemory: UInt64 {
    return getSysInfo(name: HW_PHYSMEM)
  }
  
  public var userMemory: UInt64 {
    return getSysInfo(name: HW_USERMEM)
  }
  
  public var residentMemory: UInt64 {
    return numericCast(getTaskInfo().resident_size)
  }
  
  public var virtualMemory: UInt64 {
    return numericCast(getTaskInfo().virtual_size)
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

private extension UIDevice {
  
   func getSysInfo(name: Int32) -> UInt64 {
    var mib = [CTL_HW, name]
    var size = 0
    sysctl(&mib, 2, nil, &size, nil, 0)

    let alignment: Int
    switch size {
    case 8:
      alignment = MemoryLayout<UInt64>.alignment

    default:
      alignment = MemoryLayout<UInt32>.alignment
    }

    let resultPointer = UnsafeMutableRawPointer.allocate(bytes: size, alignedTo: alignment)
    sysctl(&mib, 2, resultPointer, &size, nil, 0)

    let result: UInt64
    switch size {
    case 8:
      result = numericCast(resultPointer.assumingMemoryBound(to: UInt64.self).pointee)

    case 4:
      result = numericCast(resultPointer.assumingMemoryBound(to: UInt32.self).pointee)

    default:
      result = 0
    }

    resultPointer.deallocate(bytes: size, alignedTo: alignment)
    return result
  }
  
  func getTaskInfo() -> task_basic_info {
    var info = task_basic_info()
    var infoSize = mach_msg_type_number_t(MemoryLayout<task_basic_info>.size / MemoryLayout<natural_t>.size)
    withUnsafeMutablePointer(to: &info) { infoPointer in
      infoPointer.withMemoryRebound(to: integer_t.self, capacity: MemoryLayout<task_basic_info>.size / MemoryLayout<integer_t>.size) {
        let result = task_info(mach_task_self_, task_flavor_t(TASK_BASIC_INFO), $0, &infoSize)
        if result != KERN_SUCCESS {
          print("Failed to get task info: \(result)")
        }
      }
    }
    return info
  }
  
  func getPageSizeAndVMStatistics() -> (vm_size_t, vm_statistics) {
    let hostPort = mach_host_self()
    var pageSize: vm_size_t = 0
    let result = host_page_size(hostPort, &pageSize)
    if result != KERN_SUCCESS {
      print("Failed to get page size: \(result)")
    }

    var info = vm_statistics()
    var infoSize = mach_msg_type_number_t(MemoryLayout<vm_statistics>.size / MemoryLayout<natural_t>.size)
    withUnsafeMutablePointer(to: &info) { infoPointer in
      infoPointer.withMemoryRebound(to: integer_t.self, capacity: MemoryLayout<task_basic_info>.size / MemoryLayout<integer_t>.size) {
        let result = host_statistics(hostPort, HOST_VM_INFO, $0, &infoSize)
        if result != KERN_SUCCESS {
          print("Failed to get vm statistics: \(result)")
        }
      }
    }
    return (pageSize, info)
  }
  
}
