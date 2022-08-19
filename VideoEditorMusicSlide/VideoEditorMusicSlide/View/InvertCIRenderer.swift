//
//  InvertCIRenderer.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 29/11/2021.
//

import CoreMedia
import CoreVideo
import CoreImage

class InvertCIRenderer: FilterRenderer {
    
    var description: String = "Rosy (Core Image)"
    
    var isPrepared = false
    
    private var ciContext: CIContext?
    
    private var invertFilter: CIFilter?
    
    private var outputColorSpace: CGColorSpace?
    
    private var outputPixelBufferPool: CVPixelBufferPool?
    
    private(set) var outputFormatDescription: CMFormatDescription?
    
    private(set) var inputFormatDescription: CMFormatDescription?
    
    /// - Tag: FilterCoreImageRosy
    func prepare(with formatDescription: CMFormatDescription, outputRetainedBufferCountHint: Int) {
        reset()
        
        (outputPixelBufferPool,
         outputColorSpace,
         outputFormatDescription) = allocateOutputBufferPool(with: formatDescription,
                                                             outputRetainedBufferCountHint: outputRetainedBufferCountHint)
        if outputPixelBufferPool == nil {
            return
        }
        inputFormatDescription = formatDescription
        ciContext = CIContext()
        invertFilter = CIFilter(name: "CIColorInvert")
        isPrepared = true
    }
    
    func reset() {
        ciContext = nil
        invertFilter = nil
        outputColorSpace = nil
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        isPrepared = false
    }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let invertFilter = invertFilter,
            let ciContext = ciContext,
            isPrepared else {
                assertionFailure("Invalid state: Not prepared")
                return nil
        }
        
        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        invertFilter.setValue(sourceImage, forKey: kCIInputImageKey)
        
        guard let filteredImage = invertFilter.value(forKey: kCIOutputImageKey) as? CIImage else {
            print("CIFilter failed to render image")
            return nil
        }
        
        var pbuf: CVPixelBuffer?
        CVPixelBufferPoolCreatePixelBuffer(kCFAllocatorDefault, outputPixelBufferPool!, &pbuf)
        guard let outputPixelBuffer = pbuf else {
            print("Allocation failure")
            return nil
        }
        
        // Render the filtered image out to a pixel buffer (no locking needed, as CIContext's render method will do that)
        ciContext.render(filteredImage, to: outputPixelBuffer, bounds: filteredImage.extent, colorSpace: outputColorSpace)
        return outputPixelBuffer
    }
}

