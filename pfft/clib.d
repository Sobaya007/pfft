//          Copyright Jernej Krempuš 2012
// Distributed under the Boost Software License, Version 1.0.
//    (See accompanying file LICENSE_1_0.txt or copy at
//          http://www.boost.org/LICENSE_1_0.txt)

module pfft.clib;

import core.stdc.stdlib, core.bitop;

version(Posix)
    import core.sys.posix.stdlib, core.sys.posix.unistd;

size_t max(size_t a, size_t b){ return a > b ? a : b; } 
size_t min(size_t a, size_t b){ return a < b ? a : b; } 

size_t pagesize()
{
    static if(is(typeof(sysconf)) && is(typeof(_SC_PAGESIZE)))
        return sysconf(_SC_PAGESIZE);
    else
        // just take a guees in this case
        return 4096;
}

static if(is(typeof(posix_memalign)))
{
    auto allocate_aligned(size_t alignment, size_t size)
    {
        void* ptr;
        posix_memalign(&ptr, alignment, size);
        return ptr;
    }

    alias free free_aligned;

    size_t alignment(alias F)(size_t n)
    {
        return min(max(n, F.alignment(n)), pagesize());  
    }
}
else
{
    auto allocate_aligned(size_t alignment, size_t size)
    {
        enum psize = (void*).sizeof;
        auto p = malloc(size + alignment + psize);
        auto aligned = cast(void*)(
            (cast(size_t)p + psize + alignment) & ~(alignment - 1U));
        *cast(void**)(aligned - psize) = p;
        return aligned; 
    }

    void free_aligned(void* p)
    {
        free(*cast(void**)(p - (void*).sizeof)); 
    }

    size_t alignment(alias F)(size_t n)
    {
        static if(is(typeof(sysconf)) && is(typeof(_SC_PAGESIZE)))
            size_t page_size = sysconf(_SC_PAGESIZE);
        else
            // just take a guees in this case
            enum page_size = 4096;

        enum cache_line = 64;       

            return pagesize(); // TODO: fix this
 
        if(n < 5 * page_size)
            // align to cache line at most to avoid wasting memory 
            return min(max(n, F.alignment(n)), cache_line);
        else
            // aligne to page size, the increase of memory size isn't that
            // signifficant in this case and this can improve performance
            return pagesize();
    }
}

private void assert_power2(size_t n)
{
    if(n & (n - 1))
    {
        version(Posix)
        {
            import core.stdc.stdio; 
            fprintf(stderr, 
                "Size passed to pfft functions must be a power of two.\n");
        }
        exit(1); 
    }
}

size_t ptrsize_align(size_t n)
{
    return (n + (void*).sizeof) & ~((void*).sizeof - 1);
}

private template code(string type, string suffix, string Suffix)
{
    enum code = 
    `
        import impl_`~type~` = pfft.impl_`~type~`;

        /// A documentation comment. 
        align(1) struct PfftTable`~Suffix~`
        {
            impl_`~type~`.Table p;
            size_t log2n;
        }

        size_t pfft_table_size_bytes_`~suffix~`(size_t n)
        {
            assert_power2(n);

            return 
                ptrsize_align(impl_`~type~`.table_size_bytes(bsf(n))) +
                PfftTable`~Suffix~`.sizeof;
        }

        auto pfft_table_`~suffix~`(size_t n, void* mem)
        {
            assert_power2(n);

            auto log2n = bsf(n);

            if(mem is null)
                mem = allocate_aligned(
                    alignment!(impl_`~type~`)(n), 
                    pfft_table_size_bytes_`~suffix~`(n));

            auto table = cast(PfftTable`~Suffix~`*)(
                mem + ptrsize_align(impl_`~type~`.table_size_bytes(log2n)));

            table.p = impl_`~type~`.fft_table(bsf(n), mem);
            table.log2n = log2n;

            return table;
        }

        void pfft_table_free_`~suffix~`(PfftTable`~Suffix~`* table)
        {
            free_aligned(table.p);
        }

        void pfft_fft_`~suffix~`(`~type~`* re, `~type~`* im, PfftTable`~Suffix~`* table)
        {
            auto log2n = cast(int) table.log2n;
            impl_`~type~`.multidim_fft(
                re, im, (&log2n)[0 .. 1], (&table.p)[0 .. 1], null);
        }

        void pfft_ifft_`~suffix~`(`~type~`* re, `~type~`* im, PfftTable`~Suffix~`* table)
        {
            auto log2n = cast(int) table.log2n;
            impl_`~type~`.multidim_fft(
                im, re, (&log2n)[0 .. 1], (&table.p)[0 .. 1], null);
        }

        align(1) struct PfftRTable`~Suffix~`
        {
            impl_`~type~`.RTable rtable;
            impl_`~type~`.Table table;
            impl_`~type~`.ITable itable;
            size_t log2n;
        }

        size_t pfft_rtable_size_bytes_`~suffix~`(size_t n)
        {
            assert_power2(n);

            return 
                ptrsize_align(impl_`~type~`.itable_size_bytes(bsf(n)) +
                impl_`~type~`.table_size_bytes(bsf(n) - 1) +
                impl_`~type~`.rtable_size_bytes(bsf(n))) + 
                PfftRTable`~Suffix~`.sizeof;
        }

        auto pfft_rtable_`~suffix~`(size_t n, void* mem)
        {
            assert_power2(n);

            auto log2n = bsf(n);

            auto rtable_size = impl_`~type~`.rtable_size_bytes(log2n);
            auto table_size = impl_`~type~`.table_size_bytes(log2n - 1);
            auto itable_size = impl_`~type~`.itable_size_bytes(log2n);

            auto sz = ptrsize_align(table_size + rtable_size + itable_size);
            auto al = alignment!(impl_`~type~`)(n);

            if(mem is null)
                mem = allocate_aligned(al, sz + PfftRTable`~Suffix~`.sizeof);

            auto table = cast(PfftRTable`~Suffix~`*)(mem + sz);

            table.rtable = impl_`~type~`.rfft_table(log2n, mem);
            table.table = impl_`~type~`.fft_table(log2n - 1, mem + rtable_size);
            table.itable = impl_`~type~`.interleave_table(log2n, mem + rtable_size + table_size);
            table.log2n = log2n;

            return table;
        }

        void pfft_rtable_free_`~suffix~`(PfftRTable`~Suffix~`* table)
        {
            free_aligned(table.rtable);
        }

        void pfft_rfft_`~suffix~`(`~type~`* data, PfftRTable`~Suffix~`* table)
        {
            impl_`~type~`.deinterleave(data, cast(uint) table.log2n, table.itable);
            impl_`~type~`.rfft(
                data, data + ((cast(size_t) 1) << (table.log2n - 1)), 
                cast(uint) table.log2n, table.table, table.rtable); 
        }

        void pfft_irfft_`~suffix~`(`~type~`* data, PfftRTable`~Suffix~`* table)
        {
            impl_`~type~`.irfft(
                data, data + ((cast(size_t) 1) << (table.log2n - 1)),
                cast(uint) table.log2n, table.table, table.rtable); 
            impl_`~type~`.interleave(data, cast(uint) table.log2n, table.itable);
        }

        size_t pfft_alignment_`~suffix~`(size_t n)
        {
            assert_power2(n);

            return impl_`~type~`.alignment(n);
        }

        `~type~`* pfft_allocate_`~suffix~`(size_t n)
        {
            assert_power2(n);

            auto p = allocate_aligned(alignment!(impl_`~type~`)(n), `~type~`.sizeof * n);

            return cast(`~type~`*) p;
        }

        void pfft_free_`~suffix~`(`~type~`* p)
        {
            free_aligned(p);
        }
    `;
}

export:
extern(C):

version(Float)
    mixin(code!("float", "f", "F"));

version(Double)
    mixin(code!("double", "d", "D"));

version(Real)
    mixin(code!("real", "l", "L"));
