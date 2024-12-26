/**
 * === Array Slice as `Gee.List` ===
 *
 * GeeArraySlice makes a slice of an array as a `Gee.List`. It is read-only.
 * It's used when a function requires a `Gee.List` but we don't want to copy.
 *
 * ==== Examples ====
 *
 * {{{
 * // suppose a function that only accepts Gee.List<int> argument.
 * extern void print_gee_list(Gee.List<int> list);
 *
 * void main() {
 *     var array = new int[] {1, 2, 3, 4, 5};
 *     print_gee_list(new GeeArraySlice<int>.from(array));
 * }
 * }}}
 */
public class Musys.GeeArraySlice<ElemT>: Gee.AbstractBidirList<ElemT> {
    public unowned ElemT[] array;
    public int begin;
    public int end;

    public override int size { get { return end - begin; } }
    public override bool read_only { get { return true; } }
    public Gee.EqualDataFunc<ElemT> equal_func {
        get { return (a, b) => a == b; } set {}
    }
    public override bool @foreach (Gee.ForallFunc<ElemT> f)
    {
        foreach (var g in this.array) {
            if (!f(g))
                return false;
        }
        return true;
    }
    public override Gee.Iterator<ElemT> iterator() {
        return new Iterator<ElemT>.slice_begin(this);
    }
    public override Gee.ListIterator<ElemT> list_iterator() {
        return new Iterator<ElemT>.slice_begin(this);
    }
    public override Gee.BidirListIterator<ElemT> bidir_list_iterator() {
        return new Iterator<ElemT>.slice_begin(this);
    }
    public override bool contains(ElemT item) { return index_of(item) != -1; }
    public override int index_of(ElemT item)
    {
        for (int i = 0; i < array.length; i++)
            if (i == item) return i;
        return -1;
    }
    public override ElemT @get(int index) { return array[index]; }
    public override void @set(int index, ElemT item) { }
    public override bool add(ElemT elem)  { return false; }
    public override void insert(int index, ElemT item) {}
    public override bool remove(ElemT item) { return false; }
    public override ElemT remove_at(int index) { return null; }
    public override Gee.List<ElemT>? slice(int start, int stop)
    {
        return new GeeArraySlice<ElemT>() {
            array = this.array,
            begin = this.begin,
            end   = this.end
        };
    }
    public new Gee.List<ElemT> read_only_view { owned get { return this; } }

    public override void clear() {}

    public GeeArraySlice.from(ElemT[] array) {
        this.array = array;
        this.begin = 0;
        this.end   = array.length;
    }
    public GeeArraySlice.from_slice(ElemT[] array, int begin, int end)
    {
        if (begin > end) {
            crash_fmt("GeeArraySlice{%p[%d:%d]} begin > end", array, begin, end);
        }
        this.array = array;
        this.begin = int.max(begin, 0);
        this.end   = int.min(end, array.length);
    }

    public class Iterator<IElemT>: Object, Gee.Traversable<IElemT>, Gee.Iterator<IElemT>,
                                   Gee.BidirListIterator<IElemT>,
                                   Gee.ListIterator<IElemT>,
                                   Gee.BidirIterator<IElemT> {
        [CCode(array_length=false)]
        public unowned IElemT[] array;
        public int  begin;
        public int  end;
        public long array_index;
        public unowned GeeArraySlice<IElemT> slice;

        public bool next()
        {
            if (array_index < end)
                array_index++;
            return array_index < end;
        }
        public bool has_next() { return array_index < end; }
        public bool first() {
            array_index = begin;
            return true;
        }
        public new IElemT? get() {
            if (array_index >= array.length)
                return null;
            return array[array_index];
        }
        public void remove() {}
        public bool previous() {
            if (array_index <= begin)
                return false;
            array_index--;
            return true;
        }
        public bool has_previous() { return array_index <= begin; }
        public bool last() {
            if (begin == end)
                return false;
            array_index = end - 1;
            return true;
        }
        public new void @set(IElemT item) {}
        public void add(IElemT item) {}
        public int index() { return (int)array_index; }
        public void insert(IElemT item) {}
        public bool read_only { get { return true; } }
        public bool valid { get { return has_next(); } }
        public bool @foreach (Gee.ForallFunc<IElemT> f)
        {
            for (long idx = array_index; idx <= array.length; idx++) {
                if (!f(array[idx]))
                    return false;
            }
            return true;
        }
        public Gee.Iterator<IElemT>[] tee(uint forks) {
            if (forks == 0) {
                return new Gee.Iterator<IElemT>[0];
            } else {
                Gee.Iterator<IElemT>[] result = new Gee.Iterator<IElemT>[forks];
                result[0] = this;
                for (uint i = 1; i < forks; i++) {
                    result[i] = new Iterator<IElemT>.slice_begin(slice);
                }
                return result;
            }
        }
        public Iterator.slice_begin(GeeArraySlice slice)
        {
            this.array = slice.array;
            this.begin = slice.begin;
            this.end   = slice.end;
            this.slice = slice;
        }
    } // class Iterator<IElemT>
} // class GeeArraySlice<ElemT>
