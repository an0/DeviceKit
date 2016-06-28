//
//  UIDevice+FileSystem.swift
//  DeviceKit
//
//  Created by Ling Wang on 4/12/16.
//
//

import UIKit

public extension UIDevice {
    public func diskInfo() -> String {
        let bcFormatter = NSByteCountFormatter()
        bcFormatter.countStyle = .File
        let info = "Disk Status:\n" +
            "Total: \(bcFormatter.stringFromByteCount(numericCast(totalDiskSpace)))\n" +
            "Free: \(bcFormatter.stringFromByteCount(numericCast(freeDiskSpace)))\n";
        return info
    }

    public var totalDiskSpace: UInt64 {
        do {
            let attributes = try NSFileManager.defaultManager().attributesOfFileSystemForPath(NSHomeDirectory())
            return (attributes[NSFileSystemSize] as? NSNumber)?.unsignedLongLongValue ?? 0
        } catch {
            print(exception)
            return 0
        }
    }

    public var freeDiskSpace: UInt64 {
        do {
            let attributes = try NSFileManager.defaultManager().attributesOfFileSystemForPath(NSHomeDirectory())
            return (attributes[NSFileSystemFreeSize] as? NSNumber)?.unsignedLongLongValue ?? 0
        } catch {
            print(exception)
            return 0
        }
    }
}