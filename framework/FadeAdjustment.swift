//
// Created by 황철호 on 2021/01/06.
//
public class FadeAdjustment: BasicOperation {
    public var fade:Float = 0.0 { didSet { uniformSettings["fade"] = fade } }

    public init() {
        super.init(fragmentShader:FadeFragmentShader, numberOfInputs:1)

        ({fade = 0.0})()
    }
}
