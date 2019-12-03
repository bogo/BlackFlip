// flip dark outlines into bright using CMYK and magic numbers

import Foundation
import CoreGraphics
import UIKit

fileprivate let cubeSize = 64
fileprivate var cubeData: [Float] = {
    var cubeData = [Float]()
    let alpha: CGFloat = 1.0
    
    for z in 0 ..< cubeSize {
        let blue = CGFloat(z) / CGFloat(cubeSize-1)
        for y in 0 ..< cubeSize {
            let green = CGFloat(y) / CGFloat(cubeSize-1)
            for x in 0 ..< cubeSize {
                let red = CGFloat(x) / CGFloat(cubeSize-1)
                
                let baseColor = UIColor(red: red, green: green, blue: blue, alpha: alpha)
                let flippedColor = baseColor.blackFlip
                
                cubeData.append(contentsOf: [flippedColor.red, flippedColor.green, flippedColor.blue, flippedColor.alpha].map { Float($0) })
            }
        }
    }
    
    return cubeData
}()

infix operator &/
fileprivate extension CGFloat {
    static func &/(lhs: CGFloat, rhs: CGFloat) -> CGFloat {
        if rhs == 0 {
            return 0
        }
        return lhs/rhs
    }
}

// CMYK UIColor
public extension UIColor {
    private convenience init(cyan: CGFloat, magenta: CGFloat, yellow: CGFloat, black: CGFloat, alpha: CGFloat = 1.0) {
        precondition(
                0...1 ~= cyan &&
                0...1 ~= magenta &&
                0...1 ~= yellow &&
                0...1 ~= black &&
                0...1 ~= alpha,
                "CMYK values must be CGFloats, in 0...1 range."
        )
        
        let red = (1 - cyan) * (1 - black)
        let green = (1 - magenta) * (1 - black)
        let blue = (1 - yellow) * (1 - black)
        
        self.init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    private var isGreyish: Bool {
        (abs(red - green) <= 0.05
            && abs(green - blue) <= 0.05
            && abs(red - blue) <= 0.05)
        || black >= 0.5
    }
    
    private var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return (red, green, blue, alpha)
    }
    
    fileprivate var red: CGFloat { rgba.red }
    fileprivate var green: CGFloat { rgba.green }
    fileprivate var blue: CGFloat { rgba.blue }
    fileprivate var alpha: CGFloat { rgba.alpha }
    
    private var cyan: CGFloat { (1 - red - black) &/ (1 - black) }
    private var magenta: CGFloat { return (1 - green - black) &/ (1 - black) }
    private var yellow: CGFloat { return (1 - blue - black) &/ (1 - black) }
    private var black: CGFloat { return 1 - max(red, green, blue) }
    
    var blackFlip: UIColor {
        if !isGreyish {
            return self
        }
        
        return UIColor(cyan: 0.5 * cyan,
                       magenta: 0.5 * magenta,
                       yellow: 0.5 * yellow,
                       black: 1 - black,
                       alpha: alpha)
    }
}

public extension CIFilter {
     static func blackFlipFilter() -> CIFilter {
        let data = Data(buffer: UnsafeBufferPointer(start: &cubeData, count: cubeData.count))

        let cubeFilter = CIFilter(name: "CIColorCube")!
        cubeFilter.setValue(cubeSize, forKey: "inputCubeDimension")
        cubeFilter.setValue(data, forKey: "inputCubeData")
        
        return cubeFilter
    }
}

public extension CIImage {
    func blackFlip() -> CIImage? {
        let filter = CIFilter.blackFlipFilter()
        filter.setValue(self, forKey: kCIInputImageKey)
        return filter.outputImage
    }
}

public extension UIImage {
    func blackFlip() -> UIImage {
        let ciImage = CIImage(cgImage: self.cgImage!)
        let scale = self.scale
        let orientation = self.imageOrientation
        
        return UIImage(ciImage: ciImage.blackFlip()!,
                       scale: scale,
                       orientation: orientation)
    }
}
