//
//  UIDevice+FileSystem.swift
//  DeviceKit
//
//  Created by Ling Wang on 4/12/16.
//
//

import UIKit

@objc
public extension UIDevice {
  
  func diskInfo() -> String {
    let bcFormatter = ByteCountFormatter()
    bcFormatter.countStyle = .file
    let info = "Disk Status:\n" +
      "Total: \(bcFormatter.string(fromByteCount: numericCast(totalDiskSpace)))\n" +
      "Free: \(bcFormatter.string(fromByteCount: numericCast(freeDiskSpace)))\n"
    return info
  }

  var totalDiskSpace: UInt64 {
    do {
      let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
      return (attributes[FileAttributeKey.systemSize] as? NSNumber)?.uint64Value ?? 0
    } catch {
      print(error)
      return 0
    }
  }

  var freeDiskSpace: UInt64 {
    do {
      let attributes = try FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory())
      return (attributes[FileAttributeKey.systemFreeSize] as? NSNumber)?.uint64Value ?? 0
    } catch {
      print(error)
      return 0
    }
  }
  
}
