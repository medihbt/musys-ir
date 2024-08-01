namespace Musys.IR {
    public abstract class Value: Object {
        public enum TID {
            VALUE, USER,
            CONSTANT,   ICONST_ZERO,
            CONST_DATA, CONST_INT,  CONST_FLOAT, CONST_DATA_ZERO,
            CONST_EXPR, ARRAY_EXPR, STRUCT_EXPR,
            CONST_UNDEFINED, CONST_PTR_NULL,
            GLOBAL_OBJECT, GLOBAL_VARIABLE, FUNCTION,
            BASIC_BLOCK, FUNC_ARG,
            INSTRUCTION, IBASIC_BLOCK_TERMINATOR,
            PHI_SSA, SELECT_SSA,
            JUMP_BASE, JUMP_SSA, BR_SSA, SWITCH_SSA,
            UNREACHABLE_SSA, RET_SSA,
            UNARY_SSA, UNARYOP_SSA, CAST_SSA,
            BINARY_SSA, CALL_SSA, COMPARE_SSA,
            ALLOCA_SSA, VLA_ALLOCA_SSA, LOAD_SSA, STORE_SSA,
            ARRAY_INSERT_SSA, ARRAY_EXTRACT_SSA, GET_ELEM_PTR,
            RESERVED_COUNT;
        }

        protected TID _tid;
        public    TID  tid{ get { return _tid; } }
        protected class stdc.bool _istype[Value.TID.RESERVED_COUNT];
        protected class stdc.bool _shares_ref = false;

        public bool shares_ref { get { return _shares_ref; } }
        public bool isvalue_by_id(TID tid) {
            return this._tid == tid || _istype[tid];
        }
        public abstract void accept(IValueVisitor visitor);

        protected Type _value_type;
        public    Type  value_type{ get { return _value_type; } }

        public Gee.TreeSet<unowned Use> set_as_usee{get;}

        public void add_use_as_usee(Use use) {
            set_as_usee.add(use);
        }
        public void remove_use_as_usee(Use use) {
            set_as_usee.remove(use);
        }

        protected Value.C1(TID tid, Type value_type) {
            this._tid         = tid;
            this._value_type  = value_type;
            this._set_as_usee = new Gee.TreeSet<unowned Use>();
        }
        class construct { _istype[TID.VALUE] = true; }

        [CCode(cname="_ZN5Musys2IR5Value8ReadFuncE")]
        public delegate bool   ReadFunc   (Value operand);

        [CCode(cname="_ZN5Musys2IR5Value11ReplaceFuncE")]
        public delegate Value? ReplaceFunc(Value operand);
    }

    public abstract class User: Value {
        public OperandList operands{get;}

        protected void set_usee_type_match_self(ref Value? refv, Value? newv, Use use)
        {
            if (newv == refv)
                return;
            if (newv != null) {
                type_match_or_crash(value_type, newv.value_type,
                    {Log.FILE, Log.METHOD, Log.LINE});
            }
            replace_use(refv, newv, use);
            refv = newv;
        }

        protected User.C1(TID tid, Type value_type) {
            base.C1(tid, value_type);
            _operands = new OperandList(this);
        }
        protected User.C1_null_operand(TID tid, Type value_type) {
            base.C1(tid, value_type);
            _operands = null;
        }
        class construct { _istype[TID.USER] = true; }

        public static void replace_use(Value? oldu, Value? newu, Use use)
        {
            if (oldu != null)
                oldu.remove_use_as_usee(use);
            if (newu != null)
                newu.add_use_as_usee(use);
        }

        public static size_t get_ptr_value_align(Value ptr_value)
        {
            size_t align = 0;
            PointerType pty = value_ptr_or_crash(ptr_value);
            unowned var pvclass = ptr_value.get_class();
            var spec = pvclass.find_property("align");
            if (spec == null || spec.value_type != typeof(size_t))
                align = pty.target.instance_align;
            else
                align = (size_t)ptr_value.get_data<size_t>("align");
            return align;
        }

        protected static void set_usee_type_match(Type type, ref Value? to, Value? from, Use use)
        {
            if (to == from)  return;
            if (from != null)
                type_match_or_crash(type, from.value_type);
            User.replace_use(to, from, use);
            to = from;
        }
    }

    public abstract class Use {
        protected unowned OperandList _op_list;
        protected unowned User _user;
        internal  unowned Use  _prev;
        internal          Use  _next;
        public           Error error;

        public  abstract Value? usee{get;set;}
        internal OperandList op_list{ get { return _op_list; } }
        internal User        user {
            get { return  _user; }
            set { _user = value; }
        }

        public unowned Use attach_back(User user)
        {
            unowned var operands = user.operands;
            unowned var nodeof_tail = operands._tail;
            unowned var nodeof_prev = nodeof_tail._prev;
            _user    = user;
            _op_list = operands;
            nodeof_prev._next = this;
            nodeof_tail._prev = this;
            _next = nodeof_tail;
            _prev = nodeof_prev;
            _op_list._length++;
            return this;
        }
        public Use remove_this()
        {
            Use othis = this;
            unowned var next = _next;
            unowned var prev = _prev;
            next._prev = prev;
            prev._next = next;
            _op_list._length--;
            _op_list = null;
            return othis;
        }

        protected Use.C1(User user) {
            this._user = user;
        }
        protected Use() {}
        internal  Use.C1_for_guide(OperandList op_list) {
            this._op_list = op_list;
        }
    }

    sealed class GuideUse: Use {
        public override Value? usee { get { return null; } set {} }
        internal GuideUse(OperandList op_list) {
            base.C1_for_guide(op_list);
        }
    }

    public errordomain OperandListErr {
        INDEX_OVERFLOW
    }

    [Compact][CCode (has_type_id=false)]
    public class OperandList {
        [CCode (has_type_id=false)]
        public struct Iterator {
            public unowned Use use;
            public OperandList operand_list {
                get { return use.op_list; }
            }

            public unowned Use get() { return use; }
            public bool next()
            {
                if (use == operand_list._tail)
                    return false;
                use = use._next;
                return true;
            }
        }

        internal Use  _head;
        internal Use  _tail;
        internal uint _length;

        public   uint  length{ get { return _length; } }
        public   User  user {
            get { return _head.user; }
            set { _head.user = value; _tail.user = value; }
        }

        public Iterator iterator() { return { _head._next }; }
        public Iterator end()      { return { _tail }; }
        public unowned Use front() {
            return _head._next;
        }
        public unowned Use at(uint index)
               requires(index < length)
        {
            unowned Use cur = _head._next;
            while (index > 0) {
                cur = cur._next;
                index--;
            }
            return cur;
        }

        public OperandList(User user) {
            _head = new GuideUse(this);
            _tail = new GuideUse(this);
            _head._next = _tail;
            _tail._prev = _head;
            _head.user = user;
            _tail.user = user;
            _length = 0;
        }
    }
}
