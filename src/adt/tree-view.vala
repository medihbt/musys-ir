namespace Musys {
    /**
     * Slice and iterator of GLib.Tree as a map from KeyT to ValueT.
     *
     * It provides API for GLib.Tree to use ``foreach`` statements.
     *
     * ==== Examples ====
     *
     * {{{
     * var tree = new GLib.Tree<int, int>();
     * // WRONG CODE: GLib.Tree cannot use `foreach` statement directly.
     * foreach (var node in tree)
     *     stdout.printf("%d: %d\n", node.key, node.value);
     *
     * // CORRECT CODE: Use TreeView to iterate over GLib.Tree.
     * foreach (var node in TreeView<int, int>(tree))
     *     stdout.printf("%d: %d\n", node.key(), node.value());
     * }}}
     */
    public struct TreeView<KeyT, ValueT> {
        unowned Tree<KeyT, ValueT>      tree;
        unowned TreeNode<KeyT, ValueT>? node;

        public TreeView(Tree<KeyT, ValueT> data) {
            this.tree = data;
            this.node = null;
        }
        public TreeView.slice(Tree<KeyT, ValueT> tree, TreeNode<KeyT, ValueT>? node) {
            this.tree = tree;
            this.node = node;
        }

        public TreeView<KeyT, ValueT> iterator() {
            return this;
        }
        public unowned TreeNode<KeyT, ValueT>? @get() {
            return node;
        }
        public bool next() {
            if (node == null)
                node = tree == null? null: tree.node_first();
            else
                node = node.next();
            return node != null;
        }
    }

    /**
     * Slice and iterator of GLib.Tree as a set of ElemT.
     *
     * It provides API for GLib.Tree to use ``foreach`` statements.
     *
     * ==== Examples ====
     *
     * {{{
     * var tree = new GLib.Tree<int, int>();
     * // WRONG CODE: GLib.Tree cannot use ``foreach`` statement directly.
     * foreach (int elem in tree)
     *     stdout.printf("%d\n", elem);
     *
     * // CORRECT CODE: Use TreeSetView to iterate over GLib.Tree as a set of ``int``.
     * foreach (int i in TreeSetView<int>(tree))
     *     stdout.printf("%d\n", i);
     * }}}
     */
    public struct TreeSetView<ElemT> {
        unowned Tree<unowned ElemT, ElemT>      tree;
        unowned TreeNode<unowned ElemT, ElemT>? node;

        public TreeSetView(Tree<unowned ElemT, ElemT> data) {
            this.tree = data;
            this.node = null;
        }

        public size_t tree_size() {
            return tree.nnodes();
        }

        public TreeSetView<ElemT> iterator() {
            return this;
        }
        public unowned ElemT @get() {
            return node == null? null: node.value();
        }
        public bool next() {
            if (node == null)
                node = tree == null? null: tree.node_first();
            else
                node = node.next();
            return node != null;
        }
    }

    /** Create a view of tree set ``tree`` */
    internal TreeSetView<T> view_treeset<T>(Tree<unowned T, T> tree) {
        return TreeSetView<T>(tree);
    }
}
