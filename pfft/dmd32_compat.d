//          Copyright Guillaume Piolat 2017
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.dmd32_compat;


// Provide compatibility with x86 DMD, which doesn't define SIMD types.
version(D_SIMD)
{
}
else
{
    struct double2
    {
        double x, y;

        double2 opBinary(string op)(double2 a) if (op == "+")
        {
            return double2(x+a.x, y+a.y);
        }

        double2 opBinary(string op)(double2 a) if (op == "-")
        {
            return double2(x-a.x, y-a.y);
        }

        double2 opBinary(string op)(double2 a) if (op == "*")
        {
            return double2(x*a.x, y*a.y);
        }

    }

    struct float4
    {
        float x, y, z, w;

        float4 opBinary(string op)(float4 a) if (op == "+")
        {
            return float4(x+a.x, y+a.y, z+a.z, w+a.w);
        }

        float4 opBinary(string op)(float4 a) if (op == "-")
        {
            return float4(x-a.x, y-a.y, z-a.z, w-a.w);
        }

        float4 opBinary(string op)(float4 a) if (op == "*")
        {
            return float4(x*a.x, y*a.y, z*a.z, w*a.w);
        }
    }

    struct double4
    {
        float x, y, z, w;

        double4 opBinary(string op)(double4 a) if (op == "+")
        {
            return float4(x+a.x, y+a.y, z+a.z, w+a.w);
        }

        double4 opBinary(string op)(double4 a) if (op == "-")
        {
            return float4(x-a.x, y-a.y, z-a.z, w-a.w);
        }

        double4 opBinary(string op)(double4 a) if (op == "*")
        {
            return float4(x*a.x, y*a.y, z*a.z, w*a.w);
        }
    }

    struct float8
    {
        float a, b, c, d, e, f, g, h;

        float8 opBinary(string op)(float8 o) if (op == "+")
        {
            return float4(a+o.a, 
                          b+o.b,
                          c+o.c,
                          d+o.d,
                          e+o.e,
                          f+o.f,
                          g+o.g,
                          h+o.h);
        }

        float8 opBinary(string op)(float8 o) if (op == "-")
        {
            return float4(a-o.a, 
                          b-o.b,
                          c-o.c,
                          d-o.d,
                          e-o.e,
                          f-o.f,
                          g-o.g,
                          h-o.h);
        }

        float8 opBinary(string op)(float8 o) if (op == "*")
        {
            return float4(a*o.a, 
                          b*o.b,
                          c*o.c,
                          d*o.d,
                          e*o.e,
                          f*o.f,
                          g*o.g,
                          h*o.h);
        }
    }
}


