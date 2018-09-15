import Foundation
import NIO


/// An EventLoop that just executes tasks on an async queue. This is because
/// epoll does not run on Lambda. Scheduling is not available.
/// See this for some info (not much): https://github.com/aws/aws-sdk-java-v2/issues/193
/// GraphQL uses NIO which requires an event loop.
public class BasicEventLoop: EventLoop {
    private let key = DispatchSpecificKey<Void>()
    private let queue = DispatchQueue(label: "com.oliveroneill.WiltLib")

    public var inEventLoop: Bool {
        // Use a key to check whether the current queue is the specified one
        queue.setSpecific(key:key, value:())
        return DispatchQueue.getSpecific(key: key) != nil
    }

    public func execute(_ task: @escaping () -> Void) {
        queue.async {
            task()
        }
    }

    public func scheduleTask<T>(in: TimeAmount, _ task: @escaping () throws -> T) -> Scheduled<T> {
        fatalError("Not implemented.")
    }

    public func shutdownGracefully(queue: DispatchQueue, _ callback: @escaping (Error?) -> Void) {
        queue.async {
            callback(nil)
        }
    }
}
