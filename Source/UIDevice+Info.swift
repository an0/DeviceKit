//
//  UIDevice+Info.swift
//  DeviceKit
//
//  Created by Ling Wang on 10/2/19.
//  Copyright © 2019 Dennis Weissmann. All rights reserved.
//

import UIKit

@objc
public extension UIDevice {
  
  override var description: String {
    Device.current.description
  }

}
