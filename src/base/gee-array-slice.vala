namespace Musys {
    public class GeeArraySlice<ElemT>: Gee.AbstractCollection<ElemT>, Gee.List<ElemT> {
        public unowned ElemT[] array;
        public int begin;
        public int end;

        public override int size { get { return end - begin; } }
        public override Gee.Iterator<ElemT> iterator() {
            return new Iterator<ElemT>.slice_begin(this);
        }
        public new Gee.ListIterator<ElemT> list_iterator() {
            return new Iterator<ElemT>.slice_begin(this);
        }
        public new bool @foreach (Gee.ForallFunc<ElemT> f)
        {
            foreach (var g in this.array) {
                if (!f(g))
                    return false;
            }
            return true;
        }

        public Gee.List<ElemT>? slice(int start, int stop)
        {
            return new GeeArraySlice<ElemT>() {
                array = this.array,
                begin = this.begin,
                end   = this.end
            };
        }
        public new ElemT @get(int index) { return array[index]; }
        public new Gee.List<ElemT> read_only_view { owned get { return this; } }

        public int index_of(ElemT item)
        {
            for (int i = 0; i < array.length; i++)
                if (i == item) return i;
            return -1;
        }
        public override bool contains(ElemT item) { return index_of(item) != -1; }

        public override bool read_only { get { return true; } }
        public new void @set(int index, ElemT item) { }
        public override bool add(ElemT item) { return false; }
        public override void clear() {}
        public override bool remove(ElemT item) { return false; }
        public void insert(int index, ElemT item) {}
        public ElemT remove_at(int index) { return null; }

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

        public class Iterator<IElemT>: Object,
                                       Gee.ListIterator<IElemT>,
                                       Gee.Iterator<IElemT>,
                                       Gee.Traversable<IElemT> {
            [CCode(array_length=false)]
            public unowned IElemT[] array;
            public int  begin;
            public int  end;
            public long array_index;

            public new IElemT? get() {
                if (array_index >= array.length)
                    return null;
                return array[array_index];
            }
            public bool has_next() { return array_index < end; }
            public bool next()
            {
                if (array_index < end)
                    array_index++;
                return array_index < end;
            }
            public new bool @foreach (Gee.ForallFunc<IElemT> f)
            {
                for (long idx = array_index; idx <= array.length; idx++) {
                    if (!f(array[idx]))
                        return false;
                }
                return true;
            }
            public bool valid { get { return has_next(); } }
            public int index() { return (int)array_index; }

            public bool read_only { get { return true; } }
            public void remove() {}
            public new void @set(IElemT item) {}
            public void @add(IElemT item) {}

            public Iterator.slice_begin(GeeArraySlice slice)
            {
                this.array = slice.array;
                this.begin = slice.begin;
                this.end   = slice.end;
            }
        } // class Iterator<IElemT>
    } // class GeeArraySlice<ElemT>
}