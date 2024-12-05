namespace Musys.IROpti.CtrlFlow {
    public class DfsTree {
        public Node[] dfs_sequence;
        public int    n_reachable;
        public Tree<unowned IR.BasicBlock, Node> node_map;

        public DfsOrder            dfs_order { get; private set; }
        public unowned IR.Function func      { get; private set; }

        public unowned Node[] view_reachable()   { return this.dfs_sequence[:n_reachable]; }
        public unowned Node[] view_unreachable() { return this.dfs_sequence[n_reachable:]; }

        DfsTree.prepare(IR.Function func, DfsOrder order) {
            if (func.is_extern)
                crash_fmt("DfsTree requires function definiition but @%s is declaration", func.name);
            this.func         = func;
            this.dfs_order    = order;
            this.dfs_sequence = new Node[func.body.length];
            this.node_map     = new Tree<unowned IR.BasicBlock, Node>((a, b) => ptrcmp(a, b));

            foreach (IR.BasicBlock bb in func.body) {
                node_map.insert(bb, new Node() {
                    bb        = bb,
                    saved_id  = bb.id,
                    dfs_tree  = this,
                    dfs_index = ID_UNREACHABLE,
                });
                bb.id = ID_UNREACHABLE;
            }
        }
        void _fill_sequence(int n_reachable, bool restore_id)
        {
            if (n_reachable == dfs_sequence.length)
                return;
            int top = n_reachable;
            foreach (IR.BasicBlock bb in this.func.body) {
                Node? node = null;
                if (bb.id == ID_UNREACHABLE) {
                    node = node_map.lookup(bb);
                    node.node_index = top;
                    dfs_sequence[top] = node;
                    top++;
                }
                if (restore_id) {
                    if (node == null)
                        node = node_map.lookup(bb);
                    bb.id = node.saved_id;
                }
            }
        }
        public DfsTree.pre_order(IR.Function func, bool restore_id = false) {
            this.prepare(func, DfsOrder.PRE);
            int n_reachable = _do_pre_dfs(func.body.entry, 0);
            _fill_sequence(n_reachable, restore_id);
        }
        private int _do_pre_dfs(IR.BasicBlock bb, int order)
        {
            Node node = node_map.lookup(bb);
            node.dfs_index  = order;
            node.node_index = order;
            bb.id           = order;
            dfs_sequence[order] = node;
            order++;
            
            IR.IBasicBlockTerminator terminator = bb.terminator;
            if (!terminator.has_jump_target())
                return order;

            foreach (IR.JumpTarget jt in terminator.jump_targets) {
                IR.BasicBlock target_bb = jt.target;
                if (target_bb.id != ID_UNREACHABLE)
                    order = _do_pre_dfs(target_bb, order);
            }
            return order;
        }

        public class Node {
            public unowned IR.BasicBlock bb;
            public unowned Node?  parent;
            public unowned DfsTree dfs_tree;
            public int node_index;
            public int dfs_index;
            public int saved_id;

            public bool reachable {
                get { return dfs_index == ID_UNREACHABLE; }
            }
            public int parent_dfs_idx {
                get { return parent == null? ID_UNREACHABLE: parent.dfs_index; }
            }
        } // public class Node
        public const int ID_UNREACHABLE = -1;
    } // public class DfsTree
} // namespace Musys.IROpti.CtrlFlow
