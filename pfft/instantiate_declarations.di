module pfft.instantiate_declarations;

mixin template Instantiate()
{
    struct TableValue{};
    alias TableValue* Table;

    void fft(T* re, T* im, uint log2n, Table t);
    Table fft_table(uint log2n, void* p = null);
    void* fft_table_memory(Table table);
    uint fft_table_log2n(Table table);
    size_t fft_table_size(uint log2n);

    struct MultiTableValue{};
    alias MultiTableValue* MultiTable;

    MultiTable multi_fft_table(uint log2n, void* p);
    size_t multi_fft_table_size(size_t log2n);
    void multi_fft(T* re, T* im, MultiTable t);
    size_t multi_fft_ntransforms();

    struct MultiRTableValue{};
    alias MultiRTableValue* MultiRTable;

    MultiRTable multi_rfft_table(uint log2n, void* p);
    size_t multi_rtable_size(size_t log2n);
    void multi_rfft_complete(T* data, MultiTable t, MultiRTable rt, MultiITable it);
    size_t multi_rfft_ntransforms();

    struct RTableValue{};
    alias RTableValue* RTable;

    struct TransposeBufferValue{};
    alias TransposeBufferValue* TransposeBuffer;

    void rfft(T* re, T* im, Table t, RTable rt);
    void rfft_complete(T* data, Table t, RTable rt, ITable itable);
    void irfft(T* re, T* im, Table t, RTable rt);
    RTable rfft_table(uint log2n, void* p = null);
    size_t rtable_size(int log2n);

    void deinterleave_array(T* even, T* odd, T* interleaved, size_t n);
    void interleave_array(T* even, T* odd, T* interleaved, size_t n);
    void scale(T* data, size_t n, T factor);
    //void cmul(T*, T*, T*, T*, size_t);
    size_t alignment(size_t n);

    struct ITableValue{};
    alias ITableValue* ITable;

    size_t itable_size(uint log2n);
    ITable interleave_table(uint log2n, void* p);
    void interleave(T* p, uint log2n, ITable table);
    void deinterleave(T* p, uint log2n, ITable table);

    struct MultiITableValue{};
    alias MultiITableValue* MultiITable;
    
    size_t multi_itable_size(uint log2n);
    MultiITable multi_interleave_table(uint log2n, void* p);
    
    void set_implementation(int);
    
    size_t transpose_buffer_size(uint[] log2n);

    struct MultidimTableValue{};
    alias MultidimTableValue* MultidimTable;

    struct RealMultidimTableValue{};
    alias RealMultidimTableValue* RealMultidimTable;
    
    size_t multidim_fft_table_size(uint[] log2n);
    MultidimTable multidim_fft_table(uint[] log2n, void* ptr);
    void* multidim_fft_table_memory(MultidimTable table);
    void multidim_fft( T* re, T* im, MultidimTable table);
    size_t multidim_fft_table2_size(uint ndim);
    MultidimTable multidim_fft_table2(size_t ndim, void* ptr, TransposeBuffer buf);
    void multidim_fft_table_set(MultidimTable mt, size_t dim_index, Table table);
    
    size_t multidim_rfft_table_size(uint[] log2n);
    RealMultidimTable multidim_rfft_table(uint[] log2n, void* ptr);
    void multidim_rfft(T* p, RealMultidimTable rmt);
    void multidim_irfft(T* p, RealMultidimTable rmt);
    void* multidim_rfft_table_memory(MultidimTable table);
}

