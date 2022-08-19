//
//  BloomCIRenderer.swift
//  VideoEditorMusicSlide
//
//  Created by PHONG on 29/11/2021.
//
import CoreMedia
import CoreVideo
import CoreImage

class BloomCIRenderer: FilterRenderer {
    
    var description: String = "Rosy (Core Image)"
    
    var isPrepared = false
    
    private var ciContext: CIContext?
    
    private var bloomFilter: CIFilter?
    
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
        bloomFilter = CIFilter(name: "CIBloom")
        bloomFilter!.setValue(0.5, forKey: kCIInputIntensityKey)
        bloomFilter!.setValue(0.3, forKey: kCIInputRadiusKey)
        isPrepared = true
    }
    
    func reset() {
        ciContext = nil
        bloomFilter = nil
        outputColorSpace = nil
        outputPixelBufferPool = nil
        outputFormatDescription = nil
        inputFormatDescription = nil
        isPrepared = false
    }
    
    func render(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        guard let bloomFilter = bloomFilter,
            let ciContext = ciContext,
            isPrepared else {
                assertionFailure("Invalid state: Not prepared")
                return nil
        }
        
        let sourceImage = CIImage(cvImageBuffer: pixelBuffer)
        bloomFilter.setValue(sourceImage, forKey: kCIInputImageKey)
        
        guard let filteredImage = bloomFilter.value(forKey: kCIOutputImageKey) as? CIImage else {
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

