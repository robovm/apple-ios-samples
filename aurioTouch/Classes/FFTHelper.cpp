/*
 
     File: FFTHelper.cpp
 Abstract: This class demonstrates how to use the Accelerate framework to take Fast Fourier Transforms (FFT) of the audio data. FFTs are used to perform analysis on the captured audio data
 
  Version: 2.0
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 
 */

#include "FFTHelper.h"

// Utility includes
#include "CABitOperations.h"


const Float32 kAdjust0DB = 1.5849e-13;


FFTHelper::FFTHelper ( UInt32 inMaxFramesPerSlice )
: mSpectrumAnalysis(NULL),
mFFTNormFactor(1.0/(2*inMaxFramesPerSlice)),
mFFTLength(inMaxFramesPerSlice/2),
mLog2N(Log2Ceil(inMaxFramesPerSlice))
{
    mDspSplitComplex.realp = (Float32*) calloc(mFFTLength,sizeof(Float32));
    mDspSplitComplex.imagp = (Float32*) calloc(mFFTLength, sizeof(Float32));
    mSpectrumAnalysis = vDSP_create_fftsetup(mLog2N, kFFTRadix2);
}


FFTHelper::~FFTHelper()
{
    vDSP_destroy_fftsetup(mSpectrumAnalysis);
    free (mDspSplitComplex.realp);
    free (mDspSplitComplex.imagp);
}


void FFTHelper::ComputeFFT(Float32* inAudioData, Float32* outFFTData)
{
	if (inAudioData == NULL || outFFTData == NULL) return;
    
    //Generate a split complex vector from the real data
    vDSP_ctoz((COMPLEX *)inAudioData, 2, &mDspSplitComplex, 1, mFFTLength);
    
    //Take the fft and scale appropriately
    vDSP_fft_zrip(mSpectrumAnalysis, &mDspSplitComplex, 1, mLog2N, kFFTDirection_Forward);
    vDSP_vsmul(mDspSplitComplex.realp, 1, &mFFTNormFactor, mDspSplitComplex.realp, 1, mFFTLength);
    vDSP_vsmul(mDspSplitComplex.imagp, 1, &mFFTNormFactor, mDspSplitComplex.imagp, 1, mFFTLength);
    
    //Zero out the nyquist value
    mDspSplitComplex.imagp[0] = 0.0;
    
    //Convert the fft data to dB
    vDSP_zvmags(&mDspSplitComplex, 1, outFFTData, 1, mFFTLength);
    
    //In order to avoid taking log10 of zero, an adjusting factor is added in to make the minimum value equal -128dB
    vDSP_vsadd(outFFTData, 1, &kAdjust0DB, outFFTData, 1, mFFTLength);
    Float32 one = 1;
    vDSP_vdbcon(outFFTData, 1, &one, outFFTData, 1, mFFTLength, 0);
}
