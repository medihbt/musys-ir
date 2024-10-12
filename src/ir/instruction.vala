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
        SELECT, INDEX_EXTRACT, INDEX_INSERT, INDEX_PTR,
        LOAD, STORE, ALLOCA, DYN_ALLOCA,
        CALL, DYN_CALL, PHI,
        ICMP, FCMP,
        INTRIN, RESERVED_CNT;

        public bool is_shift_op()  { return SHL  <= this <= ASHR; }
        public bool is_logic_op()  { return AND  <= this <= ASHR || this == NOT; }
        public bool is_int_op()    { return AND  <= this <= UREM; }
        public bool is_float_op()  { return FADD <= this <= FREM; }
        public bool is_binary_op() { return AND  <= this <= FREM; }
        public bool is_divrem_op() {
            return SDIV <= this <= UREM || this == FREM || this == FDIV;
        }
        public unowned string get_name() {
            return this >= RESERVED_CNT?
                    "<undefined-opcode>":
                    _instruction_opcode_names[this];
        }
    }

    public abstract class Instruction: User {
        protected OpCode _opcode;
        public    OpCode  opcode { get { return _opcode; } }

        protected unowned BasicBlock _parent;
        public    unowned BasicBlock  parent {
            get { return  _parent; }
            set { _parent = value; }
        }

        internal InstructionList.Node* _nodeof_this;
        public   InstructionList.Modifier  modifier {
            get { return {_nodeof_this}; }
        }
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
        public virtual BasicBlock? default_target {
            get { return null; } set {}
        }

        /**
         * ntargets -- 这条指令的跳转目标个数. 对于重复的跳转目标, 重复几次
         * 就算几次, 不合并计算.
         * - `ntargets > 0` 表示该指令存在跳转目标且为 ntargets 个.
         * - `ntargets = 0` 表示该指令**没有跳转目标**.
         * - `ntargets < 0` 表示该指令的跳转目标**数量不固定**, 或者遇到其他错误.
         */
        public virtual int64 ntargets{ get { return 0; } }

        /**
         * ==== 遍历读取跳转目标 ====
         * {{{foreach_target(ReadFunc = {(bb) => terminates?})}}}
         *
         * 遍历读取所有的跳转目标, 每读取一个就传入迭代闭包 fn 执行一次. 倘若没有跳转目标
         * 可以读取了, 或者 fn 返回 true, 就停止迭代.
         *
         * 该方法也是一个迭代方法, 返回 true 表示迭代过程被异常终止, 返回 false 表示迭代
         * 从头到尾没有被打断.
         *
         * @param fn 迭代闭包, 接受一个基本块参数, 返回是否立即终止当前的读取.
         *
         * @return 该方法也是一个迭代方法, 返回 true 表示迭代过程被异常终止, 返回 false
         *         表示迭代从头到尾没有被打断.
         *
         * @see Musys.IR.BasicBlock.ReadFunc
         */
        public abstract bool foreach_target(BasicBlock.ReadFunc fn);

        /**
         * ==== 遍历替换跳转目标 ====
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
        "select", "extractelement", "insertelement", "getelementptr",
        "load", "store", "alloca", "dyn-alloca", "call", "phi",
        "icmp", "fcmp",  "intrin"
    };
}
