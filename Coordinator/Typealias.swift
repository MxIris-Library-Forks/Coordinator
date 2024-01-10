//
//  Typealias.swift
//  Coordinator
//
//  Created by JH on 2024/1/10.
//  Copyright © 2024 Radiant Tap. All rights reserved.
//

import Foundation
#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit

public typealias Responder = NSResponder
public typealias ViewController = NSViewController
#endif

#if canImport(UIKit)
import UIKit
public typealias Responder = UIResponder
public typealias ViewController = UIViewController
#endif
