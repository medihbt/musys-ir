/**
 * === Disjoint Set Union ===
 *
 * ''path compression enabled''. Time complexity: α(size).
 */
public class Musys.DSU {
    public int[] parent;
    public int size() { return parent.length; }

    /** Reset this DSU. */
    public void reset() {
        for (int i = 0; i < parent.length; i++)
            parent[i] = i;
    }

    /** Find root of element ``elem``. Do something when compressing paths. */
    public int find(int elem, PathZipAction? on_path_zip = null)
    {
        assert_in_range(elem, 0, this.size());
        if (parent[elem] == elem)
            return elem;
        int p = parent[elem];
        parent[elem] = find(p, on_path_zip);
        if (on_path_zip != null)
            on_path_zip(p, elem);
        return parent[elem];
    }

    public void unite(int x, int y, PathZipAction? on_path_zip = null) {
        if (x == y)
            return;
        parent[find(x, on_path_zip)] = find(y, on_path_zip);
    }

    public DSU.sized(int size) {
        this.parent = new int[size];
        for (int i = 0; i < this.parent.length; i++)
            parent[i] = i;
    }
    public DSU.merge(DSU left, DSU right) {
        this.parent = new int[left.size() + right.size()];
        int right_begin = left.size();
        for (int i = 0; i < right_begin; i++)
            this.parent[i] = left.parent[i];
        for (int i = 0; i < right.size(); i++)
            this.parent[i + right_begin] = right.parent[i] + right_begin;
    }

    public static inline bool in_range(int x, int lo, int hi) {
        if (likely(lo <= x < hi))
            return true;
        critical("[Range overflow] requires [%d, %d) but got %d", lo, hi, x);
        return false;
    }
    public static inline void assert_in_range(int x, int lo, int hi)
    {
        if (likely(in_range(x, lo, hi)))
            return;
        crash("assertion x in [lo, hi) failed");
    }

    public delegate void PathZipAction(int mid_parent, int elem);
    public const int ID_UNREACHABLE = -1;
} // public class Musys.DSU