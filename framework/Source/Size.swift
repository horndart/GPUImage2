
#if os(iOS)
import UIKit
#endif

public struct Size {
    public let width:Float
    public let height:Float
    
    public init(width:Float, height:Float) {
        self.width = width
        self.height = height
    }

    #if !os(Linux)
    public init(size: CGSize) {
        self.width = Float(size.width)
        self.height = Float(size.height)
    }
    #endif

}