namespace Musys {
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

    internal TreeSetView<T> view_treeset<T>(Tree<unowned T, T> tree) {
        return TreeSetView<T>(tree);
    }
}
