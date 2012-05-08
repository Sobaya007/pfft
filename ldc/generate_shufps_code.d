#!/usr/bin/env rdmd
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio;

enum usage = q"EOS
Usage:
    %s [c|d]
EOS";

enum shufpsTemplate = q{
auto shufps(int m0, int m1, int m2, int m3)(%s a, %s b)
{
    
    enum sm = m3 | (m2<<2) | (m1<<4) | (m0<<6);
    mixin("auto r = shufps" ~ sm.stringof ~ "(a, b);");
    return r;
}    
};

void printUsage(string[] args)
{
    writefln(usage, "generate_shufps_code");
}

void main(string[] args)
{    
    if(args.length != 3 || !(args[2] == "avx" || args[2] == "sse" ))
        return printUsage(args);
    
    if(args[1] == "c")
    {
        auto t = args[2] == "avx" ? "__m256" : "__m128";
        auto s = args[2] == "avx" ? "256" : "";

        writefln("#include <%smmintrin.h>", args[2] == "avx" ? "i" : "x");
             
        foreach(i; 0 .. 256)
            writefln("%s shufps%d(%s a, %s b){ return _mm%s_shuffle_ps(a, b, %d); }", t, i, t, t, s, i);
    }
    else if(args[1] == "d")
    {
        auto t = args[2] == "avx" ? "float8" : "float4";

        writeln("import core.simd;");

        foreach(i; 0 .. 256)
            writefln("extern(C) %s shufps%d(%s, %s);", t, i, t, t);
        
        writefln(shufpsTemplate, t, t);
    }
    else
        printUsage(args);
}