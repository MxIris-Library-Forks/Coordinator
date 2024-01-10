//
//  UIKit-CoordinatingExtensions.swift
//  Radiant Tap Essentials
//
//  Copyright © 2016 Radiant Tap
//  MIT License · http://choosealicense.com/licenses/mit/
//

#if canImport(AppKit) && !targetEnvironment(macCatalyst)
import AppKit
#endif

#if canImport(UIKit)
import UIKit
#endif

//	Inject parentCoordinator property into all NS/UIViewControllers
extension ViewController {
    private class WeakCoordinatingTrampoline: NSObject {
        weak var coordinating: Coordinating?
    }

    private struct AssociatedKeys {
		//	per: https://github.com/atrick/swift-evolution/blob/diagnose-implicit-raw-bitwise/proposals/nnnn-implicit-raw-bitwise-conversion.md#workarounds-for-common-cases
		static var ParentCoordinator: Void?
    }

    public weak var parentCoordinator: Coordinating? {
        get {
            let trampoline = objc_getAssociatedObject(self, &AssociatedKeys.ParentCoordinator) as? WeakCoordinatingTrampoline
            return trampoline?.coordinating
        }
        set {
            let trampoline = WeakCoordinatingTrampoline()
            trampoline.coordinating = newValue
            objc_setAssociatedObject(self, &AssociatedKeys.ParentCoordinator, trampoline, .OBJC_ASSOCIATION_RETAIN)
        }
    }
}




/**
Driving engine of the message passing through the app, with no need for Delegate pattern nor Singletons.

It piggy-backs on the `NS/UIResponder.next` in order to pass the message through NSUIView/NSUIVC hierarchy of any depth and complexity.
However, it does not interfere with the regular `NS/UIResponder` functionality.

At the `NS/UIViewController` level (see below), it‘s intercepted to switch up to the coordinator, if the NSUIVC has one.
Once that happens, it stays in the `Coordinator` hierarchy, since coordinator can be nested only inside other coordinators.
*/
extension Responder {
	@objc open var coordinatingResponder: Responder? {
        #if canImport(AppKit) && !targetEnvironment(macCatalyst)
        return nextResponder
        #endif
        
        #if canImport(UIKit)
        return next
        #endif
	}

	/*
	// sort-of implementation of the custom message/command to put into your Coordinable extension

	func messageTemplate(args: Whatever, sender: Any? = nil) {
	coordinatingResponder?.messageTemplate(args: args, sender: sender)
	}
	*/
}

extension Responder {
	///	Searches upwards the responder chain for the `Coordinator` that manages current `NS/UIViewController`
	public var containingCoordinator: Coordinating? {
		if let vc = self as? ViewController, let pc = vc.parentCoordinator {
			return pc
		}
		
		return coordinatingResponder?.containingCoordinator
	}
}


extension ViewController {
/**
	Returns `parentCoordinator` if this controller has one,
	or its parent `NS/UIViewController` if it has one,
	or its view's `superview`.

	Copied from `NS/UIResponder.next` documentation:

	- The `NS/UIResponder` class does not store or set the next responder automatically,
	instead returning nil by default.

	- Subclasses must override this method to set the next responder.

	- NS/UIViewController implements the method by returning its view’s superview;
	- UIWindow returns the application object, and NS/UIApplication returns nil.
*/
	override open var coordinatingResponder: Responder? {
		guard let parentCoordinator = self.parentCoordinator else {
			guard let parentController = self.parent else {
				guard let presentingController = self.presentingViewController else {
					return view.superview
				}
				return presentingController as Responder
			}
			return parentController as Responder
		}
		return parentCoordinator as? Responder
	}
}

