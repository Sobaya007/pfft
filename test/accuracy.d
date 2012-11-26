#!/usr/bin/env rdmd
//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

import std.stdio, std.process, std.string, std.range, std.algorithm, 
    std.conv, std.file, std.format, std.exception, std.parallelism, 
    std.getopt, std.path : absolutePath;

alias format fm;

@property p(string[] a)
{
    version(OSX)   // Avoid a bug on OSX.
        return a;
    else
        return taskPool.parallel(a);
}

shared verbose = 1;

auto vshell(string cmd, int vcmd, int vout)
{
    if(verbose >= vcmd) 
        writeln(cmd); 
   
    auto r = shell(cmd);
    if(verbose >= vout)
        write(r);

    return r; 
}


void test(string common = "")
{
    auto toleratedError = [
        "float" : 1e-6,
        "double": 2e-15,
        "real"  : 2e-18];

    foreach(flags;  ["", "-r", "-i", "-i -r"].p)
    foreach(impl;   ["pfft", "c", "std"].p)
    foreach(type;   ["float", "double", "real"])
    foreach(log2n;  iota(1, 21))
    {
        auto path =  absolutePath(fm("test_%s", type));
        auto cmd = fm(`%s %s %s "%s" %s`, path, flags, impl, log2n, common);
        scope(failure)
            writefln("Error when executing %s.", cmd);

        auto output = vshell(cmd, 3, 4);
        scope(failure)
            writefln("Command output was %s", output);
        auto err = to!double(strip(output));
        auto tolerated = toleratedError[type];

        enforce(err < tolerated, fm(
            "Command %s returned relative error %s, but only %s is tolerated for type %s",
            cmd, err, tolerated, type));
    }
}

void build(string flags)
{
    scope(failure)
        writefln("Error when building with flags: %s", flags);

    auto dir = getcwd();
    chdir("..");
    vshell(fm("rdmd build.d %s", flags), 2, 2);
    vshell(fm("rdmd build.d --tests %s", flags), 2, 2);
    chdir(dir); 
}

void all()
{
    auto f = (string prepend, string[] simd) =>
        simd.map!(a => fm("%s --simd %s", prepend, a))().array();

    version(linux)
    {
        auto flags = 
            f("--dc GDC", ["avx", "sse-avx", "sse", "scalar"]) ~
            f("--dc LDC",  ["avx", "sse", "scalar"]) ~
            f("--dc DMD",  ["sse", "scalar"]) ~
            f(`--dc DMD --dc-cmd "dmd -m32"`,  ["scalar"]) ~
            f(`--dc GDC --dc-cmd "gdc -m32"`, ["avx", "sse-avx", "sse", "scalar"]);
    }
    else version(OSX)
    {
        auto flags = 
            f(`--dc DMD --dc-cmd="dmd -m32"`,  ["sse", "scalar"]) ~
            f("--dc DMD",  ["sse", "scalar"]);
    }
    else version(Windows)
    {
        auto flags = 
            f("--dc GDC --no-pgo", ["sse", "scalar"]) ~
            f("--dc DMD",  ["scalar"]) ~
            f(`--dc GDC --no-pgo --dc-cmd "gdc -m32"`, ["sse", "scalar"]);
    }
    else
        static assert("Not supported on this platform.");
    
    foreach(e; flags)
    {
        build(e);
        scope(failure)
            writefln(
                "Error when running tests for executables built with %s", e);
                
        test();
        if(verbose)
		writefln("Successfully ran tests for build flags %s.", e);
    }
}

void main(string[] args)
{
    string flags = "";
    getopt(args, "v", &verbose, "flags", &flags);

    if(args[1 .. $] == ["all"])
        all();
    else
        test(flags);
}
