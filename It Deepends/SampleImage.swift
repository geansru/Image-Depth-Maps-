/// Copyright (c) 2020 Razeware LLC
///
/// Permission is hereby granted, free of charge, to any person obtaining a copy
/// of this software and associated documentation files (the "Software"), to deal
/// in the Software without restriction, including without limitation the rights
/// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
/// copies of the Software, and to permit persons to whom the Software is
/// furnished to do so, subject to the following conditions:
///
/// The above copyright notice and this permission notice shall be included in
/// all copies or substantial portions of the Software.
///
/// Notwithstanding the foregoing, you may not use, copy, modify, merge, publish,
/// distribute, sublicense, create a derivative work, and/or sell copies of the
/// Software in any work that is designed, intended, or marketed for pedagogical or
/// instructional purposes related to programming, coding, application development,
/// or information technology.  Permission for such use, copying, modification,
/// merger, publication, distribution, sublicensing, creation of derivative works,
/// or sale is expressly withheld.
///
/// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
/// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
/// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
/// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
/// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
/// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
/// THE SOFTWARE.

import AVFoundation
import UIKit

struct SampleImage {
  let url: URL
  let original: UIImage
  let depthData: UIImage
  let filterImage: CIImage

  init?(url: URL) {
    guard
      let original = UIImage(named: url.lastPathComponent),
      let depthData = SampleImage.depthData(forItemAt: url),
      let filterImage = CIImage(image: original)
      else {
        return nil
    }

    self.url = url
    self.original = original
    self.depthData = depthData
    self.filterImage = filterImage.oriented(original.imageOrientation.cgImageOrientation)
  }

  static func depthData(forItemAt url: URL) -> UIImage? {
    guard let depthDataMap = depthDataMap(forItemAt: url) else {
      assertionFailure("DepthDataMap is expected to be set")
      return nil
    }
    depthDataMap.normalize()
    let ciImage = CIImage(cvPixelBuffer: depthDataMap)
    return UIImage(ciImage: ciImage)
  }

  static func depthDataMap(forItemAt url: URL) -> CVPixelBuffer? {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
    
    let cfAuxDataInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(source, 0, kCGImageAuxiliaryDataTypeDisparity)
    guard let auxDataInfo = cfAuxDataInfo as? [AnyHashable: Any] else { return nil }
    
    let cfProperties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
    guard
      let properties = cfProperties as? [CFString: Any],
      let orientationValue = properties[kCGImagePropertyOrientation] as? UInt32,
      let orientation = CGImagePropertyOrientation(rawValue: orientationValue)
      else {
        return nil
    }

    guard var depthData = try? AVDepthData(fromDictionaryRepresentation: auxDataInfo) else { return nil }
    
    if depthData.depthDataType != kCVPixelFormatType_DisparityFloat32 {
      depthData = depthData.converting(toDepthDataType: kCVPixelFormatType_DisparityFloat32)
    }
    let depthDataWithOrientation = depthData.applyingExifOrientation(orientation).depthDataMap
    return depthDataWithOrientation
  }
  
}

private extension UIImage.Orientation {
  var cgImageOrientation: CGImagePropertyOrientation {
    switch self {
    case .up:
      return .up
    case .down:
      return .down
    case .left:
      return .left
    case .right:
      return .right
    case .upMirrored:
      return .upMirrored
    case .downMirrored:
      return .downMirrored
    case .leftMirrored:
      return .leftMirrored
    case .rightMirrored:
      return .rightMirrored
    @unknown default:
      fatalError()
    }
  }
}
