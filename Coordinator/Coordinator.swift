//
//  Coordinator.swift
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


///	Simple closure which allows you to wrap any coordinatingResponder method and
///	add it into a `queuedMessages` array on the Coordinator.
///
///	You need to do this in case method needs a dependency that may not be available
///	at that particular moment. So save it until dependencies are updated.
public typealias CoordinatingQueuedMessage = () -> Void


/**
Coordinators are a design pattern that encourages decoupling view controllers
in such a way that they know as little as possible about how they are presented.
View Controllers should never directly push/pop or present other VCs.
They should not be aware of their existence.

**That is Coordinator's job.**

Coordinators can be “nested” such that child coordinators encapsulate different flows
and prevent any one of them from becoming too large.

Each coordinator has an identifier to simplify logging and debugging.
Identifier is also used as key for the `childCoordinators` dictionary.

You should never use this class directly (although you can).
Make a proper subclass and add specific behavior for the given particular usage.

Note: Don't overthink this. Idea is to have fairly small number of coordinators in the app.
If you embed controllers into other VC (thus using them as simple UI components),
then keep that flow inside the given container controller.
Expose to Coordinator only those behaviors that cause push/pop/present to bubble up.
*/


///	Main Coordinator instance, where T is NS/UIViewController or any of its subclasses.
@MainActor
open class Coordinator<T: ViewController>: Responder, Coordinating {
	public let rootViewController: T


	/// You need to supply NS/UIViewController (or any of its subclasses) that will be loaded as root of the UI hierarchy.
	///	Usually one of container controllers (UINavigationController, UITabBarController etc).
	///
	/// - parameter rootViewController: NS/UIViewController at the top of the hierarchy.
	/// - returns: Coordinator instance, fully prepared but started yet.
	///
	///	Note: if you override this init, you must call `super`.
	public init(rootViewController: T?) {
		guard let rvc = rootViewController else {
			preconditionFailure("Must supply UIViewController (or any of its subclasses) or override this init and instantiate VC in there.")
		}
		self.rootViewController = rvc
		super.init()
	}

    #if canImport(AppKit) && !targetEnvironment(macCatalyst)
    public required init?(coder: NSCoder) {
        fatalError("")
    }
    #endif


	open lazy var identifier: String = {
		return String(describing: type(of: self))
	}()


	///	Next coordinatingResponder for any Coordinator instance is its parent Coordinator.
	open override var coordinatingResponder: Responder? {
		return parent as? Responder
	}




	//	MARK:- Lifecycle

	private(set) public var isStarted: Bool = false

	/// Tells the coordinator to create/display its initial view controller and take over the user flow.
	///	Use this method to configure your `rootViewController` (if it isn't already).
	///
	///	Some examples:
	///	* instantiate and assign `viewControllers` for UINavigationController or UITabBarController
	///	* assign itself (Coordinator) as delegate for the shown UIViewController(s)
	///	* setup closure entry/exit points
	///	etc.
	///
	///	- Parameter completion: An optional `Callback` executed at the end.
	///
	///	Note: if you override this method, you must call `super` and pass the `completion` closure.
	open func start() async {
		rootViewController.parentCoordinator = self
		isStarted = true
	}

	/// Tells the coordinator that it is done and that it should
	///	clear out its backyard.
	///
	///	Possible stuff to do here: dismiss presented controller or pop back pushed ones.
	///
	///	- Parameter completion: Closure to execute at the end.
	///
	///	Note: if you override this method, you must call `super` and pass the `completion` closure.
	open func stop() async {
		rootViewController.parentCoordinator = nil
	}

	///	By default, calls `stopChild` on the given Coordinator, passing in the `completion` block.
	///
	///	(See also comments for this method in the Coordinating protocol)
	///
	///	Note: if you override this method, you should call `super` and pass the `completion` closure.
	open func coordinatorDidFinish(_ coordinator: Coordinating) async {
		await stopChild(coordinator: coordinator)
	}

	///	Coordinator can be in memory, but it‘s not currently displaying anything.
	///	For example, parentCoordinator started some other Coordinator which then took over root VC to display its VCs,
	///	but did not stop this one.
	///
	///	Parent Coordinator can then re-activate this one, in which case it should take-over the
	///	the ownership of the root VC.
	///
	///	Note: if you override this method, you should call `super`
	///
	///	By default, it sets itself as `parentCoordinator` for its `rootViewController`.
	open func activate() {
		rootViewController.parentCoordinator = self
	}

	///	This should activate relevant Coordinator + remove any shown UIVCs from other Coordinators.
	///
	///	By default, it just calls `activate()`
	open func takeover() {
		activate()
	}



	//	MARK:- Containment

	open weak var parent: Coordinating?

	///	A dictionary of child Coordinators, where key is Coordinator's identifier property.
	///	The only way to add/remove something is through `startChild` / `stopChild` methods.
	private(set) public var childCoordinators: [String: Coordinating] = [:]

	/**
	Adds new child coordinator and starts it.

	- Parameter coordinator: The coordinator implementation to start.
	- Parameter completion: An optional `Callback` passed to the coordinator's `start()` method.
	*/
	public func startChild(coordinator: Coordinating) async {
		childCoordinators[coordinator.identifier] = coordinator
		coordinator.parent = self
		await coordinator.start()
	}


	/**
	Stops the given child coordinator and removes it from the `childCoordinators` array

	- Parameter coordinator: The coordinator implementation to stop.
	- Parameter completion: An optional `Callback` passed to the coordinator's `stop()` method.
	*/
	public func stopChild(coordinator: Coordinating) async {
		coordinator.parent = nil
		self.childCoordinators.removeValue(forKey: coordinator.identifier)
		await coordinator.stop()
	}


	//	MARK:- Queuing coordinatingResponder methods

	///	Temporary keeper for methods requiring dependency which is not available yet.
	private(set) public var queuedMessages: [CoordinatingQueuedMessage] = []

	///	Simply add the message wrapped in the closure. Mind the capture list for `self` and other objects.
	public func enqueueMessage(_ message: @escaping CoordinatingQueuedMessage ) {
		queuedMessages.append( message )
	}

	///	Call this each time your Coordinator's dependencies are updated.
	///	It will go through all the queued closures and try to execute them again.
	public func processQueuedMessages() {
		//	make a local copy
		let arr = queuedMessages
		//	clean up the queue, in case it's re-populated while this pass is ongoing
		queuedMessages.removeAll()
		//	execute each message
		arr.forEach { $0() }
	}
}

