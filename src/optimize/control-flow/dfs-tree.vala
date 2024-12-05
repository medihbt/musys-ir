/** DFS sequence in CFG with a parent node. */
public class Musys.IROpti.CtrlFlow.DfsSequence {
    /**
     * DFS sequence with reachable and unreachable basic blocks.
     * This sequence starts with REACHABLE nodes and ends with
     * UNREACHABLE nodes.
     */
    public Node[] dfs_sequence;

    /** Number of reachable nodes in dfs_sequence. */
    public int    n_reachable;

    /** Prevent basic block id from being changed by others */
    public Tree<unowned IR.BasicBlock, Node> node_map;

    public DfsOrder            dfs_order { get; private set; }
    public unowned IR.Function func      { get; private set; }

    /** ``this.dfs_sequence[:n_reachable]`` contains reachable nodes */
    public unowned Node[] view_reachable()   { return this.dfs_sequence[:n_reachable]; }

    /** ``this.dfs_sequence[n_reachable:]`` contains unreachable nodes */
    public unowned Node[] view_unreachable() { return this.dfs_sequence[n_reachable:]; }

    public void restore_basicblock_id()
    {
        foreach (Node node in dfs_sequence)
            node.bb.id = node.saved_id;
    }

    void _init_complete(int n_reachable, bool restore_id)
    {
        if (n_reachable == dfs_sequence.length)
            return;
        int top = n_reachable;
        foreach (IR.BasicBlock bb in this.func.body) {
            if (bb.id == ID_UNREACHABLE) {
                Node node = node_map.lookup(bb);
                node.node_index   = top;
                dfs_sequence[top] = node;
                top++;
            }
        }
        if (restore_id)
            this.restore_basicblock_id();
    }
    DfsSequence.prepare(IR.Function func, DfsOrder order) {
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
                dfs_seq   = this,
                dfs_index = ID_UNREACHABLE,
            });
            bb.id = ID_UNREACHABLE;
        }
    }
    /** Traverse ``func.body`` in Pre-order and build this DFS sequence. */
    public DfsSequence.pre_order(IR.Function func, bool restore_id = false) {
        this.prepare(func, DfsOrder.PRE);
        int n_reachable = _do_pre_dfs(func.body.entry, 0, null);
        this._init_complete(n_reachable, restore_id);
    }
    /** Traverse ``func.body`` in Post-order and build this DFS sequence. */
    public DfsSequence.post_order(IR.Function func, bool restore_id = false) {
        this.prepare(func, DfsOrder.POST);
        int n_reachable = _do_post_dfs(func.body._entry, 0, null);
        this._init_complete(n_reachable, restore_id);
    }
    private int _do_pre_dfs(IR.BasicBlock bb, int order, Node? parent)
    {
        Node node = node_map.lookup(bb);
        node.dfs_index  = order;
        node.node_index = order;
        node.parent     = parent;
        bb.id           = order;
        dfs_sequence[order] = node;
        order++;

        IR.IBasicBlockTerminator terminator = bb.terminator;
        if (!terminator.has_jump_target())
            return order;

        foreach (IR.JumpTarget jt in terminator.jump_targets) {
            IR.BasicBlock target_bb = jt.target;
            if (target_bb.id != ID_UNREACHABLE)
                continue;
            order = _do_pre_dfs(target_bb, order, node);
        }
        return order;
    }
    private int _do_post_dfs(IR.BasicBlock bb, int order, Node? parent)
    {
        Node node = node_map.lookup(bb);
        bb.id = ID_REACHABLE_TAKEN;

        IR.IBasicBlockTerminator terminator = bb.terminator;
        if (terminator.has_jump_target()) {
            foreach (IR.JumpTarget jt in terminator.jump_targets) {
                IR.BasicBlock target_bb = jt.target;
                if (target_bb.id != ID_UNREACHABLE)
                    continue;
                order = _do_post_dfs(target_bb, order, node);
            }
        }

        node.dfs_index  = order;
        node.node_index = order;
        node.parent     = parent;
        bb.id           = order;
        dfs_sequence[order] = node;
        return order + 1;
    }

    public class Node {
        public unowned IR.BasicBlock bb;
        public unowned Node?  parent;
        public unowned DfsSequence dfs_seq;
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
    public  const int ID_UNREACHABLE     = -1;
    private const int ID_REACHABLE_TAKEN = 0;
} // public class Musys.IROpti.CtrlFlow.DfsTree
