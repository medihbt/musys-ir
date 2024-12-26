/**
 * Stack containing intergers with an array inside.
 *
 * NOTE: This is not a specialization of VecStack<int>.
 */
public class Musys.IntVecStack {
    public   int[] data;
    internal int  _size;
    public   int   size { get { return _size; } }

    public int  get(int index) {
        return this.data[index];
    }
    public void set(int index, int value) {
        this.data[index] = value;
    }

    public int topv()     { return this.data[size - 1]; }
    public int topindex() { return this.size - 1; }
    public bool empty()   { return this.size == 0; }

    public int pop() {
        this._size--;
        return this.data[this.size];
    }
    public void push(int value)
    {
        this._size++;
        if (this.data == null || this.data.length == 0)
            this.data = new int[1];
        if (this.size >= this.data.length)
            this.data.resize(this.data.length * 2);
        this.data[this.size] = value;
    }

    public IntVecStack() {
        this.data = new int[0];
    }
    public IntVecStack.sized(int size) {
        this.data = new int[size];
    }
} // public class Musys.VecStack

/** Stack containing gneric type T elements with an array inside. */
public class Musys.VecStack<T> {
    public   T[]  data;
    internal int _size;
    public   int  size { get { return _size; } }

    public T? get(int index) {
        return 0 < index < size ? this.data[index]: null;
    }
    public void set(int index, int value) {
        this.data[index] = value;
    }

    public T?  topv() { return size > 0? this.data[size - 1]: null; }
    public int topindex() { return this.size - 1; }
    public bool empty()   { return this.size == 0; }

    public T? pop() {
        if (this.empty())
            return null;
        this._size--;
        return this.data[this.size];
    }
    public void push(int value)
    {
        this._size++;
        if (this.data == null || this.data.length == 0)
            this.data = new T[1];
        if (this.size >= this.data.length)
            this.data.resize(this.data.length * 2);
        this.data[this.size] = value;
    }

    public VecStack() {
        this.data = new T[0];
    }
    public VecStack.sized(int size) {
        this.data = new T[size];
    }
} // public class Musys.VecStack

