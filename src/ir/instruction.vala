namespace Musys.IR {
    public enum OpCode {
        NONE,
        AND,  ORR,  XOR,  SHL,  LSHR, ASHR, 
        ADD,  SUB,  MUL,  SDIV, UDIV, SREM, UREM,
        FADD, FSUB, FMUL, FDIV, FREM,
        JMP, BR, SWITCH, RET, UNREACHABLE,
        INEG, FNEG, NOT,
        SITOFP, UITOFP, FPTOSI, ZEXT, SEXT, TRUNC, FPEXT, FPTRUNC,
        BITCAST, INT_TO_PTR, PTR_TO_INT,
        SELECT, INDEX_EXTRACT, INDEX_INSERT, INDEX_PTR, INDEX_OFFSET_OF,
        LOAD, STORE, ALLOCA, DYN_ALLOCA,
        CALL, DYN_CALL, PHI,
        ICMP, FCMP,
        CONST_ARRAY, CONST_STRUCT, CONST_VEC,
        INTRIN, RESERVED_CNT;

        public bool is_shift_op()  { return SHL  <= this <= ASHR; }
        public bool is_logic_op()  { return AND  <= this <= ASHR || this == NOT; }
        public bool is_int_op()    { return AND  <= this <= UREM; }
        public bool is_float_op()  { return FADD <= this <= FREM; }
        public bool is_binary_op() { return AND  <= this <= FREM; }
        public bool is_divrem_op() {
            return SDIV <= this <= UREM || this == FREM || this == FDIV;
        }
        public bool is_constexpr_op() {
            return (AND <= this <= FREM) || (INDEX_EXTRACT <= this <= INDEX_OFFSET_OF);
        }
        public bool is_inst_op() {
            return this != INDEX_OFFSET_OF && !(CONST_ARRAY <= this <= CONST_VEC);
        }
        public unowned string get_name() {
            return this >= RESERVED_CNT?
                    "<undefined-opcode>":
                    _instruction_opcode_names[this];
        }
    }

    /**
     * === Musys 指令类 ===
     *
     * 指令结点, 同时表示指令执行的结果. 指令的类型就是结果的类型.
     */
    public abstract class Instruction: User {
        /**
        * 操作码：表示指令执行的具体操作. 指令一旦构造完成, 操作码不可更改.
        *
        * @see Musys.IR.OpCode
        */
        public    OpCode  opcode { get { return _opcode; } }
        protected OpCode _opcode;

        /** 指令在 IR 结点树中的父结点. */
        public    unowned BasicBlock  parent {
            get { return  _parent; }
            set { _parent = value; }
        }
        protected unowned BasicBlock _parent;

        /**
         * 返回指向指令自己的修改式迭代器. 你可以用这个迭代器完成增删改操作.
         * 倘若你调用两次该属性分别得到 a 和 b 迭代器, 那修改一个迭代器的具体
         * 内容时, 另一个不受影响.
         *
         * @see Musys.IR.InstructionList.Modifier
         */
        public   InstructionList.Modifier  modifier {
            get { return {_nodeof_this}; }
        }
        internal InstructionList.Node* _nodeof_this;
        public bool is_attached() { return modifier.is_available(); }

        public virtual void on_plug(BasicBlock parent) {
            _parent = parent;
        }
        public virtual unowned BasicBlock on_unplug()
        {
            unowned BasicBlock ret = _parent;
            _parent = null;
            return ret;
        }
        public virtual void on_parent_finalize()   { this._deep_clean(); }
        public virtual void on_function_finalize() { this._fast_clean(); }
        protected void _fast_clean() { _nodeof_this = null; }
        protected void _deep_clean() {
            _nodeof_this = null; _parent = null;
        }

        protected Instruction.C1(Value.TID tid, OpCode opcode, Type type)
        {
            base.C1(tid, type);
            _opcode = opcode;
        }
        ~Instruction() {
            if (_nodeof_this != null) {
                unowned string iklass = get_class().get_name();
                unowned string opcode = opcode.to_string();
                crash_fmt(
                    "Instruction %p(id %d, opcode %s, class %s) still connected to list",
                    this, id, opcode, iklass);
            }
        }
        class construct { _istype[TID.INSTRUCTION] = true; }
    }

    /**
     * 基本块终止子. 只有实现该接口的指令类才能放在基本块末尾.
     * @see BasicBlock
     */
    public interface IBasicBlockTerminator: Instruction {
        /**
         * 默认跳转目标.
         *
         * 基本块终止子可能会有一个默认跳转目标. 在 br 指令里, 跳转目标是条件为 false
         * 的分支; 在只有一个跳转目标的 jump 指令里, 默认跳转目标就是那仅有的一个; 在
         * 像 ret/unreachable 这样直接终止控制流的指令里没有跳转目标, 此时 default_target
         * 属性应当为 null,
         */
        public virtual BasicBlock? default_target { get { return null; } set {} }

        /**
         * ntargets -- 这条指令的跳转目标个数. 对于重复的跳转目标, 重复几次
         * 就算几次, 不合并计算.
         * - `ntargets > 0` 表示该指令存在跳转目标且为 ntargets 个.
         * - `ntargets = 0` 表示该指令**没有跳转目标**.
         * - `ntargets < 0` 表示该指令的跳转目标**数量不固定**, 或者遇到其他错误.
         */
        public virtual int64 ntargets{ get { return 0; } }

        /**
         * 遍历读取跳转目标.
         *
         * {{{foreach_target(ReadFunc = {(bb) => terminates?})}}}
         *
         * 遍历读取所有的跳转目标, 每读取一个就传入迭代闭包 fn 执行一次. 倘若没有跳转目标
         * 可以读取了, 或者 fn 返回 true, 就停止迭代.
         *
         * 该方法也是一个迭代方法, 返回 true 表示迭代过程被异常终止, 返回 false 表示迭代
         * 从头到尾没有被打断.
         *
         * ''注意, 这个迭代返回值的含义和 Gee 是恰好相反的.''
         *
         * @param fn 迭代闭包, 接受一个基本块参数, 返回是否立即终止当前的读取.
         *
         * @return 该方法也是一个迭代方法, 返回 true 表示迭代过程被异常终止, 返回 false
         *         表示迭代从头到尾没有被打断. ''注意, 这个迭代返回值的含义和 Gee
         *         是恰好相反的.''
         *
         * @see Musys.IR.BasicBlock.ReadFunc
         */
        public abstract bool foreach_target(BasicBlock.ReadFunc fn);

        /**
         * 遍历替换跳转目标.
         *
         * {{{replace_target(ReadFunc = {(bb) => replacement?})}}}
         *
         * @param fn 迭代替换闭包. 接受一个基本块参数, 返回是否立即终止当前替换, 以及
         * 是否替换目标.
         *
         * @return 该方法也是一个迭代方法, 返回 true 表示迭代过程被异常终止, 返回 false
         *         表示迭代从头到尾没有被打断.
         *
         * ''注意, 这个迭代返回值的含义和 Gee 是恰好相反的.''
         *
         * @see Musys.IR.BasicBlock.ReplaceFunc
         */
        public abstract bool replace_target(BasicBlock.ReplaceFunc fn);
    }

    private unowned string _instruction_opcode_names[OpCode.RESERVED_CNT] = {
        "<undefined>",
        "and", "or", "xor", "shl",  "lshr", "ashr", 
        "add", "sub", "mul", "sdiv", "udiv", "srem", "urem",
        "fadd", "fsub", "fmul", "fdiv", "frem",
        "br", "br", "switch", "ret", "unreachable",
        "ineg", "fneg", "not",
        "sitofp", "uitofp", "fptosi", "zext", "sext", "trunc", "fpext", "fptrunc",
        "bitcast", "inttoptr", "ptrtoint",
        "select", "extractelement", "insertelement", "getelementptr", "offsetof",
        "load", "store", "alloca", "dyn-alloca", "call", "phi",
        "icmp", "fcmp",
        "constarray", "conststruct", "constvec",
        "intrin"
    };
}
