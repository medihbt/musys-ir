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
        CALL, PHI,
        ICMP, FCMP,
        INTRIN, RESERVED_CNT;

        public bool is_shift_op()  { return SHL  <= this <= ASHR; }
        public bool is_logic_op()  { return AND  <= this <= ASHR || this == NOT; }
        public bool is_int_op()    { return AND  <= this <= UREM; }
        public bool is_float_op()  { return FADD <= this <= FREM; }
        public bool is_binary_op() { return AND  <= this <= FREM; }
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
                crash_fmt({Log.FILE, Log.METHOD, Log.LINE},
                    "Instruction %p(id %d, opcode %s, class %s) still connected to list",
                    this, id, opcode, iklass);
            }
        }
        class construct { _istype[TID.INSTRUCTION] = true; }
    }

    public interface IBasicBlockTerminator: Instruction {
        public virtual BasicBlock? default_target {
            get { return null; } set {}
        }

        public abstract void forEachTarget(BasicBlock.ReadFunc fn);
        public abstract void replaceTarget(BasicBlock.ReplaceFunc fn);
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
