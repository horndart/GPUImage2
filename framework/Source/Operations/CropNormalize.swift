
public class CropNormalize: BasicOperation {
    public var minSize: Float = 0.2
    public var maxSize: Float = 1
    public var locationOfCropNorm: Position = Position(0, 0)
    public var cropSizeNorm: Size = Size(width: 1, height: 1)
    public var hasFixedRatio: Bool = true

    public init() {
        super.init(fragmentShader:PassthroughFragmentShader, numberOfInputs:1)
    }

//    private func getInputSize() -> GLSize?{
//        inputFramebuffers[0]?.sizeForTargetOrientation(.portrait)
//    }
//    private func getActualCropRatio(inputSize: GLSize) -> Size{
//        let inputSize = Size(width: Float(inputSize.width), height: Float(inputSize.height))
//        return Size(width: cropRatio.width / inputSize.width, height: cropRatio.height / inputSize.height)
//    }

    public func move(dx: Float, dy: Float){
        let newLocationX = locationOfCropNorm.x - dx
        let newLocationY = locationOfCropNorm.y - dy

        locationOfCropNorm = Position(
                btw(0, newLocationX, 1 - cropSizeNorm.width),
                btw(0, newLocationY, 1 - cropSizeNorm.height)
        )
    }

    public func scale(scale: Float, pivotNormInVisible: Position = Position(0.5, 0.5)){
        let pivotPointX: Float
        let pivotPointY: Float
        pivotPointX = locationOfCropNorm.x + cropSizeNorm.width * pivotNormInVisible.x
        pivotPointY = locationOfCropNorm.y + cropSizeNorm.height * pivotNormInVisible.y
        var scaledCropSizeNorm = Size(width: self.cropSizeNorm.width * scale, height: self.cropSizeNorm.height * scale)
        if hasFixedRatio{
            let maxSize = max(scaledCropSizeNorm.width, scaledCropSizeNorm.height)
            let minSize = min(scaledCropSizeNorm.width, scaledCropSizeNorm.height)
            if maxSize > 1{
                scaledCropSizeNorm = Size(width: scaledCropSizeNorm.width / maxSize, height: scaledCropSizeNorm.height / maxSize)
            }
            if minSize < self.minSize{
                scaledCropSizeNorm = Size(width: scaledCropSizeNorm.width / minSize * self.minSize, height: scaledCropSizeNorm.height / minSize * self.minSize)
            }
        }else{
            scaledCropSizeNorm = Size(width: btw(minSize, scaledCropSizeNorm.width, 1), height: btw(minSize, scaledCropSizeNorm.height, 1))
        }
        cropSizeNorm = scaledCropSizeNorm
        locationOfCropNorm = Position(
                btw(0, pivotPointX - scaledCropSizeNorm.width * pivotNormInVisible.x, 1 - scaledCropSizeNorm.width),
                btw(0, pivotPointY - scaledCropSizeNorm.height * pivotNormInVisible.y, 1 - scaledCropSizeNorm.height)
        )
    }

    override func renderFrame() {
        let inputFramebuffer:Framebuffer = inputFramebuffers[0]!
        let inputSize = inputFramebuffer.sizeForTargetOrientation(.portrait)
        let cropSize = cropSizeNorm.denormalize(by: inputSize)
        let locationOfCrop = locationOfCropNorm.denormalize(by: inputSize)

        let finalCropSize:GLSize
        let normalizedOffsetFromOrigin:Position
        let glCropSize = GLSize(cropSize)

        finalCropSize = GLSize(width:min(inputSize.width, glCropSize.width), height:min(inputSize.height, glCropSize.height))
        normalizedOffsetFromOrigin = Position(locationOfCrop.x / Float(inputSize.width), locationOfCrop.y / Float(inputSize.height))

        let normalizedCropSize = Size(width:Float(finalCropSize.width) / Float(inputSize.width), height:Float(finalCropSize.height) / Float(inputSize.height))
        
        renderFramebuffer = sharedImageProcessingContext.framebufferCache.requestFramebufferWithProperties(orientation:.portrait, size:finalCropSize, stencil:false)
        
        let textureProperties = InputTextureProperties(textureCoordinates:inputFramebuffer.orientation.rotationNeededForOrientation(.portrait).croppedTextureCoordinates(offsetFromOrigin:normalizedOffsetFromOrigin, cropSize:normalizedCropSize), texture:inputFramebuffer.texture)
        
        renderFramebuffer.activateFramebufferForRendering()
        clearFramebufferWithColor(backgroundColor)
        renderQuadWithShader(shader, uniformSettings:uniformSettings, vertexBufferObject:sharedImageProcessingContext.standardImageVBO, inputTextures:[textureProperties])
        releaseIncomingFramebuffers()
    }
}

@inlinable public func btw<T>(_ minV: T, _ x: T, _ maxV: T) -> T where T : Comparable{
    min(max(minV, x), maxV)
}

private extension Size{
    func denormalize(by size: GLSize) -> Size{
        Size(width: self.width * Float(size.width), height: self.height * Float(size.height))
    }
}
private extension Position{
    func denormalize(by size: GLSize) -> Position{
        Position(self.x * Float(size.width), self.y * Float(size.height))
    }
}