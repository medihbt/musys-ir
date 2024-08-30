public errordomain Musys.IR.InstructionListErr {
    INST_ATTACHED, INST_UNATTACHED
}

public class Musys.IR.InstructionList {
    internal Node _node_begin;
    internal Node _node_end;

    internal unowned BasicBlock _parent;
    public unowned BasicBlock parent {
        get { return _parent;  }
        set { _parent = value; }
    }

    public size_t length{get;}

    public bool is_empty() {
        return _node_begin._next == &_node_end;
    }
    public unowned Instruction front() {
        if (is_empty()) {
            crash_fmt({Log.FILE, Log.METHOD, Log.LINE},
                      "Instruction List %p is empty", this);
        }
        return _node_begin._next->item;
    }
    public unowned Instruction back() {
        if (is_empty()) {
            crash_fmt({Log.FILE, Log.METHOD, Log.LINE},
                      "Instruction List %p is empty", this);
        }
        return _node_end._prev->item;
    }
    public Iterator iterator() { return {&_node_begin}; }

    public void append(Instruction inst)
    {
        try {
            Modifier() { node = _node_end._prev }.append(inst);
        } catch (InstructionListErr e) {
            crash_fmt({Log.FILE, Log.METHOD, Log.LINE},
                      "%s.%s msg %s",
                      e.domain.to_string(),
                      e.code.to_string(),
                      e.message);
        }
    }
    public void prepend(Instruction inst)
    {
        try {
            Modifier() { node = _node_begin._next }.prepend(inst);
        } catch (InstructionListErr e) {
            crash("%s.%s msg %s"
                .printf(e.domain.to_string(),
                        e.code.to_string(),
                        e.message));
        }
    }
    public void clean()
    {
        if (is_empty())
            return;
        Node *cur  = _node_begin._next;
        while (cur != &_node_end) {
            Node *cached = cur;
            cur = cur->_next;
            Node.Finalize(cached);
        }
        _node_begin._next = &_node_end;
        _node_end._prev   = &_node_begin;
    }

    public InstructionList.empty(BasicBlock parent) { _init_empty(parent); }
    public InstructionList.move(InstructionList another)
    {
        if (another.is_empty()) {
            _init_empty(another.parent);
            return;
        }
        Node *node_front = another._node_begin._next;
        Node *node_back  = another._node_end._prev;
        this._node_begin = Node() {
            _list = this, item  = null,
            _prev = null, _next = node_front,
        };
        this._node_end = Node() {
            _list = this, item  = null,
            _next = null, _prev = node_back
        };
        node_front->_prev = &_node_begin;
        node_back->_next  = &_node_end;
    }
    ~InstructionList() { clean(); }

    private void _init_empty(BasicBlock parent)
    {
        this._length     = 0;
        this._node_begin = Node() {
            _list = this, _prev = null,
            item  = null, _next = &_node_end
        };
        this._node_end   = Node() {
            _list = this, _prev = &_node_begin,
            item  = null, _next = null
        };
        this._parent = parent;
    }

    [CCode (has_type_id=false)]
    public struct Node {
        unowned InstructionList _list;
        Node*      _prev;
        Node*      _next;
        Instruction item;

        [CCode (cname="Musys_IR_InstructionList_Node_Create")]
        internal static Node* Create(InstructionList list, Instruction  item,
                                     Node*    prev = null, Node* next = null)
        {
            var ret = (Node*)malloc0(sizeof(Node));
            ret->_list = list;
            ret->item  = item;
            ret->_prev = prev;
            ret->_next = next;
            item._nodeof_this = ret;
            return ret;
        }

        [CCode (cname="Musys_IR_InstructionList_Node_Finalize")]
        internal static void Finalize(Node *node)
        {
            node->_list = null;
            node->_prev = null;
            node->_next = null;
            node->item  = null;
            free(node);
        }
    }

    public struct Iterator {
        public Node*           node;
        public InstructionList list { get { return node->_list; } }
        public Instruction get() { return node->item; }
        public bool next()
        {
            if (node == null)
                crash("node is NULL!\n", true, {Log.FILE, Log.METHOD, Log.LINE});
            if (node->_next == null) {
                warning("touched end of BasicBlock %p(%d)",
                        list.parent, list.parent.id);
                return false;
            }
            node = node->_next;
            if (node->_next == null)
                return false;
            return true;
        }
        public Iterator get_prev() { return {node->_prev}; }
        public Iterator get_next() { return {node->_next}; }
        public bool is_available() {
            return node != null && node->item != null;
        }
        public void disable() { node = null; }
        public bool ends() {
            return node == null || node->_next == null;
        }
    }

    public struct Modifier: Iterator {
        public Modifier append(Instruction inst) throws InstructionListErr
        {
            BasicBlock block = list._parent;
            Modifier ret = append_raw(inst);
            inst.on_plug(block);
            return ret;
        }
        public Modifier prepend(Instruction inst) throws InstructionListErr
        {
            BasicBlock block = list._parent;
            Modifier ret = prepend_raw(inst);
            inst.on_plug(block);
            return ret;
        }
        internal Modifier append_raw(Instruction inst) throws InstructionListErr
        {
            unowned var list = this.list;
            if (!this.is_available() && list._parent == null) {
                crash("node %p is not available for list %p"
                        .printf(node, list));
            }
            if (inst.is_attached()) {
                unowned string iklass = inst.get_class().get_name();
                unowned string opcode = inst.opcode.to_string();
                throw new InstructionListErr.INST_ATTACHED(
                    "Requires instruction %p(class %s, opcode %s) not attached, but attached to list %p (this %p)"
                    .printf(inst, iklass, opcode, inst.modifier.list, list)
                );
            }
            Node* next     = node->_next;
            Node* new_node = Node.Create(list, inst, node, next);
            node->_next = new_node;
            next->_prev = new_node;
            inst._nodeof_this = new_node;
            list._length++;
            return {new_node};
        }
        internal Modifier prepend_raw(Instruction inst) throws InstructionListErr
        {
            if (!this.is_available() && list._parent == null) {
                crash("node %p is not available for list %p"
                        .printf(node, list));
            }
            if (inst.modifier.is_available()) {
                throw new InstructionListErr.INST_ATTACHED(
                    "instruction %p attached to list %p (this %p)"
                    .printf(inst, inst.modifier.list, list)
                );
            }
            Node* prev     = node->_prev;
            Node* new_node = Node.Create(list, inst, prev, node);
            node->_prev = new_node;
            prev->_next = new_node;
            inst._nodeof_this = new_node;
            list._length++;
            return {new_node};
        }
        public Instruction replace(Instruction new_item) throws InstructionListErr
        {
            Instruction old_item = get();
            if (new_item == old_item)
                return old_item;
            if (!this.is_available()) {
                crash("node %p is not available for list %p"
                        .printf(node, list));
            }
            if (new_item.is_attached()) {
                throw new InstructionListErr.INST_ATTACHED(
                    "instruction %p attached to list %p (this %p)"
                    .printf(new_item, new_item.modifier.list, list)
                );
            }
            Node            *original = node;
            unowned BasicBlock parent = old_item.on_unplug();
            original->item = new_item;
            new_item.on_plug(parent);
            new_item._nodeof_this = node;
            old_item._nodeof_this = null;
            return old_item;
        }
        public Instruction unplug()
        {
            if (!this.is_available()) {
                crash("node %p is not available for list %p"
                        .printf(node, list));
            }
            var ret = node->item;
            unowned var list = this.list;
            ret.on_unplug();
            Node *prev = node->_prev;
            Node *next = node->_next;
            prev->_next = next; next->_prev = prev;
            Node.Finalize(node); node = null;
            list._length--;
            ret._nodeof_this = null;
            return ret;
        }
    }
}
