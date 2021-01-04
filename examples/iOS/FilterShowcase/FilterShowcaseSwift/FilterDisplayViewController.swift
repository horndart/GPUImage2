import UIKit
import GPUImage
import AVFoundation

let blendImageName = "WID-small.jpg"

class FilterDisplayViewController: UIViewController, UISplitViewControllerDelegate {

    @IBOutlet var filterSlider: UISlider!
    @IBOutlet var filterView: RenderView!
//    @IBOutlet var scrollView: UIScrollView!
    
    let videoCamera:Camera?
    var blendImage:PictureInput?

    var cropOperation = CropNormalize()

    required init(coder aDecoder: NSCoder)
    {
        do {
            videoCamera = try Camera(sessionPreset:.vga640x480, location:.backFacing)
            videoCamera!.runBenchmark = true
        } catch {
            videoCamera = nil
            print("Couldn't initialize camera with error: \(error)")
        }

        super.init(coder: aDecoder)!
    }
    
    var filterOperation: FilterOperationInterface?

    func configureView() {
        guard let videoCamera = videoCamera else {
            let errorAlertController = UIAlertController(title: NSLocalizedString("Error", comment: "Error"), message: "Couldn't initialize camera", preferredStyle: .alert)
            errorAlertController.addAction(UIAlertAction(title: NSLocalizedString("OK", comment: "OK"), style: .default, handler: nil))
            self.present(errorAlertController, animated: true, completion: nil)
            return
        }
//        scrollView.delegate = self
        if let currentFilterConfiguration = self.filterOperation {
            self.title = currentFilterConfiguration.titleName

            cropOperation.cropSizeNorm = Size(width: 1, height: 0.75)

            // Configure the filter chain, ending with the view
            if let view = self.filterView {
                switch currentFilterConfiguration.filterOperationType {
                case .singleInput:
                    videoCamera.addTarget(cropOperation)
                    cropOperation.addTarget(currentFilterConfiguration.filter)
                    currentFilterConfiguration.filter.addTarget(view)
                case .blend:
                    videoCamera.addTarget(cropOperation)
                    cropOperation.addTarget(currentFilterConfiguration.filter)
                    self.blendImage = PictureInput(imageName:blendImageName)
                    self.blendImage?.addTarget(currentFilterConfiguration.filter)
                    self.blendImage?.processImage()
                    currentFilterConfiguration.filter.addTarget(view)
                case let .custom(filterSetupFunction:setupFunction):
                    videoCamera.addTarget(cropOperation)
                    currentFilterConfiguration.configureCustomFilter(setupFunction(cropOperation, currentFilterConfiguration.filter, view))
                }
                
                videoCamera.startCapture()
            }

            // Hide or display the slider, based on whether the filter needs it
            if let slider = self.filterSlider {
                switch currentFilterConfiguration.sliderConfiguration {
                case .disabled:
                    slider.isHidden = true
//                case let .Enabled(minimumValue, initialValue, maximumValue, filterSliderCallback):
                case let .enabled(minimumValue, maximumValue, initialValue):
                    slider.minimumValue = minimumValue
                    slider.maximumValue = maximumValue
                    slider.value = initialValue
                    slider.isHidden = false
                    self.updateSliderValue()
                }
            }
            
        }
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.panAction(_:)))
        filterView?.addGestureRecognizer(panGesture)
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(self.pinchAction(_:)))
        filterView?.addGestureRecognizer(pinchGesture)
    }
    private var lastPanGesturePoint: CGPoint = .zero
    @objc func panAction(_ gesture: UIPanGestureRecognizer){
        if gesture.state == .began{
            lastPanGesturePoint = gesture.location(in: gesture.view)
        }else if gesture.state == .changed{
            let width = Float(gesture.view!.bounds.width)
            let height = Float(gesture.view!.bounds.height)
            let point = gesture.location(in: gesture.view)
            let cropSizeNorm = cropOperation.cropSizeNorm
            let dx = Float(point.x - lastPanGesturePoint.x) / (width / cropSizeNorm.width)
            let dy = Float(point.y - lastPanGesturePoint.y) / (height / cropSizeNorm.height)
            cropOperation.move(dx: dx, dy: dy)
            lastPanGesturePoint = point
        }
    }

    @objc func pinchAction(_ gesture: UIPinchGestureRecognizer){
        if gesture.state == .changed{
            let scale = 1 / gesture.scale
            var point = gesture.location(in: gesture.view)
            point.x = point.x / gesture.view!.bounds.width
            point.y = point.y / gesture.view!.bounds.height
            cropOperation.scale(scale: Float(scale), pivotNormInVisible: Position(Float(point.x), Float(point.y)))
        }
        gesture.scale = 1
    }
    
    @IBAction func updateSliderValue() {
        if let currentFilterConfiguration = self.filterOperation {
            switch (currentFilterConfiguration.sliderConfiguration) {
                case .enabled(_, _, _): currentFilterConfiguration.updateBasedOnSliderValue(Float(self.filterSlider!.value))
                case .disabled: break
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.configureView()
    }

    override func viewWillDisappear(_ animated: Bool) {
        if let videoCamera = videoCamera {
            videoCamera.stopCapture()
            videoCamera.removeAllTargets()
            blendImage?.removeAllTargets()
        }
        
        super.viewWillDisappear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


public extension Matrix4x4 {
    func asTransform3D() -> CATransform3D{
        CATransform3D(
                m11: CGFloat(m11),
                m12: CGFloat(m12),
                m13: CGFloat(m13),
                m14: CGFloat(m14),
                m21: CGFloat(m21),
                m22: CGFloat(m22),
                m23: CGFloat(m23),
                m24: CGFloat(m24),
                m31: CGFloat(m31),
                m32: CGFloat(m32),
                m33: CGFloat(m33),
                m34: CGFloat(m34),
                m41: CGFloat(m41),
                m42: CGFloat(m42),
                m43: CGFloat(m43),
                m44: CGFloat(m44)
        )
    }
}

extension FilterDisplayViewController: UIScrollViewDelegate{
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        filterView
    }
}
