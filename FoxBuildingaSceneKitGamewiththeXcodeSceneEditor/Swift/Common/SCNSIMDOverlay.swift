/*
Copyright (C) 2015 Apple Inc. All Rights Reserved.
See LICENSE.txt for this sample’s licensing information

*/

import Foundation
import SceneKit
import simd

// TEMP until overlay is included in Swift

//////////////////////////////////
// MARK: Overlay 1

#if os(OSX)
    typealias SCNFloat = CGFloat
    #else
    typealias SCNFloat = Float
#endif

//////////////////////////////////
// MARK: SIMD Overlay

extension SCNVector3 {
    init(_ x: Float, _ y: Float, _ z: Float) {
        self.x = SCNFloat(x)
        self.y = SCNFloat(y)
        self.z = SCNFloat(z)
    }
    init(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat) {
        self.x = SCNFloat(x)
        self.y = SCNFloat(y)
        self.z = SCNFloat(z)
    }
    init(_ x: Double, _ y: Double, _ z: Double) {
        self.init(SCNFloat(x), SCNFloat(y), SCNFloat(z))
    }
    init(_ x: Int, _ y: Int, _ z: Int) {
        self.init(SCNFloat(x), SCNFloat(y), SCNFloat(z))
    }
    init(_ v: float3) {
        self.init(SCNFloat(v.x), SCNFloat(v.y), SCNFloat(v.z))
    }
    init(_ v: double3) {
        self.init(SCNFloat(v.x), SCNFloat(v.y), SCNFloat(v.z))
    }
}

extension float3 {
    init(_ v: SCNVector3) {
        self.init(Float(v.x), Float(v.y), Float(v.z))
    }
}

extension double3 {
    init(_ v: SCNVector3) {
        self.init(Double(v.x), Double(v.y), Double(v.z))
    }
}

extension SCNVector4 {
    init(_ x: Float, _ y: Float, _ z: Float, _ w: Float) {
        self.x = SCNFloat(x)
        self.y = SCNFloat(y)
        self.z = SCNFloat(z)
        self.w = SCNFloat(w)
    }
    init(_ x: CGFloat, _ y: CGFloat, _ z: CGFloat, _ w: CGFloat) {
        self.x = SCNFloat(x)
        self.y = SCNFloat(y)
        self.z = SCNFloat(z)
        self.w = SCNFloat(w)
    }
    init(_ x: Double, _ y: Double, _ z: Double, _ w: Double) {
        self.init(SCNFloat(x), SCNFloat(y), SCNFloat(z), SCNFloat(w))
    }
    init(_ x: Int, _ y: Int, _ z: Int, _ w: Int) {
        self.init(SCNFloat(x), SCNFloat(y), SCNFloat(z), SCNFloat(w))
    }
    init(_ v: float4) {
        self.init(SCNFloat(v.x), SCNFloat(v.y), SCNFloat(v.z), SCNFloat(v.w))
    }
    init(_ v: double4) {
        self.init(SCNFloat(v.x), SCNFloat(v.y), SCNFloat(v.z), SCNFloat(v.w))
    }
}

extension float4 {
    init(_ v: SCNVector4) {
        self.init(Float(v.x), Float(v.y), Float(v.z), Float(v.w))
    }
}

extension double4 {
    init(_ v: SCNVector4) {
        self.init(Double(v.x), Double(v.y), Double(v.z), Double(v.w))
    }
}

extension SCNMatrix4 {
    init(_ m: float4x4) {
        self.init(
            m11: SCNFloat(m[0,0]), m12: SCNFloat(m[0,1]), m13: SCNFloat(m[0,2]), m14: SCNFloat(m[0,3]),
            m21: SCNFloat(m[1,0]), m22: SCNFloat(m[1,1]), m23: SCNFloat(m[1,2]), m24: SCNFloat(m[1,3]),
            m31: SCNFloat(m[2,0]), m32: SCNFloat(m[2,1]), m33: SCNFloat(m[2,2]), m34: SCNFloat(m[2,3]),
            m41: SCNFloat(m[3,0]), m42: SCNFloat(m[3,1]), m43: SCNFloat(m[3,2]), m44: SCNFloat(m[3,3]))
    }
    init(_ m: double4x4) {
        self.init(
            m11: SCNFloat(m[0,0]), m12: SCNFloat(m[0,1]), m13: SCNFloat(m[0,2]), m14: SCNFloat(m[0,3]),
            m21: SCNFloat(m[1,0]), m22: SCNFloat(m[1,1]), m23: SCNFloat(m[1,2]), m24: SCNFloat(m[1,3]),
            m31: SCNFloat(m[2,0]), m32: SCNFloat(m[2,1]), m33: SCNFloat(m[2,2]), m34: SCNFloat(m[2,3]),
            m41: SCNFloat(m[3,0]), m42: SCNFloat(m[3,1]), m43: SCNFloat(m[3,2]), m44: SCNFloat(m[3,3]))
    }
}

extension float4x4 {
    init(_ m: SCNMatrix4) {
        self.init([float4(Float(m.m11), Float(m.m12), Float(m.m13), Float(m.m14)),
            float4(Float(m.m21), Float(m.m22), Float(m.m23), Float(m.m24)),
            float4(Float(m.m31), Float(m.m32), Float(m.m33), Float(m.m34)),
            float4(Float(m.m41), Float(m.m42), Float(m.m43), Float(m.m44))
            ])
    }
}

extension double4x4 {
    init(_ m: SCNMatrix4) {
        self.init([double4(Double(m.m11), Double(m.m12), Double(m.m13), Double(m.m14)),
            double4(Double(m.m21), Double(m.m22), Double(m.m23), Double(m.m24)),
            double4(Double(m.m31), Double(m.m32), Double(m.m33), Double(m.m34)),
            double4(Double(m.m41), Double(m.m42), Double(m.m43), Double(m.m44))
            ])
    }
}