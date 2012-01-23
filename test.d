import std.stdio, std.range, std.algorithm, std.conv, 
    std.math, std.numeric, std.complex, std.random;

import pfft.sse;

auto rms(R)(R r)
{
    return sqrt(reduce!q{ a + b.re^^2 + b.im^^2 }(0.0, r) / r.length);
}

void main(string[] args)
{
    int log2n = parse!int(args[1]);
    int n = 1<<log2n;
    
    auto re = new float[n];
    auto im = new float[n];
    auto c = new Complex!(double)[n];
    
    rndGen.seed(1);
    foreach(i, e; re)
    {
        c[i].re = uniform(0.0,1.0);
        c[i].im = uniform(0.0,1.0);
        re[i] = c[i].re;
        im[i] = c[i].im;
    }
    
    auto ft = (new Fft(n)).fft!float(c);
    
    auto tables = fft_table(log2n);
    fft(re.ptr, im.ptr, log2n, tables);
    
    auto diff = map!
        ((a){ return a[2] - complex(a[0], a[1]); })
        (zip(re, im, ft));
    
    writefln("%.2e", rms(diff) / rms(ft));
}
