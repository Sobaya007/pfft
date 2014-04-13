//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.impl_double;
import pfft.fft_impl;

version(SSE_AVX)
{
    import pfft.detect_avx;
    import sse = pfft.sse_double, avx = pfft.avx_double;

    mixin Instantiate!(
        "double", get, FFT!(sse.Vector!(), sse.Options!()), avx);
}
else
{
    version(Scalar)
        import pfft.scalar_double;
    else version(Neon)
        import pfft.neon_double;
    else version(StdSimd)
        import pfft.stdsimd;
    else version(AVX)
        import pfft.avx_double;
    else
        import pfft.sse_double;
    
    mixin Instantiate!("double", 0, FFT!(Vector!(),Options!()));
}

