/**
 * 一切有函数调用结构的指令——调用类指令. 通常来说, 只要存在 `xxx(a, b, c)` 这种
 * 结构的指令都可以算调用类指令.
 *
 * 每个调用类指令都有一个函数类型 `callee_fn_type` 作为约束. 对于有实际函数的调用
 * 指令(如 call, vcall, invoke), `callee_fn_type` 就是对应的函数类型. 其他指令
 * (如 intrin) 就不是了, 它们的函数类型是虽随着指令本身生成的.
 *
 * 调用类指令都有**参数列表**, 即属性 `uargs`. 参数信息的类型是 `ArgUse`, 兼任
 * 数据流图边和函数参数信息两个角色. 倘若 `callee_fn_type` 的参数不是变长的, 那
 * `uargs` 的长度应该严格等于 `callee_fn_type` 的参数列表长度, 否则前者严格不小于
 * 后者.
 */
public abstract class Musys.IR.CallBase: Instruction {
    protected unowned FunctionType _callee_fn_type;
    /** 调用者的函数类型, 即这条指令的参数类型约束. */
    public    unowned FunctionType  callee_fn_type {
        get { return _callee_fn_type; }
        internal set { _callee_fn_type = value; }
    }
    /** callee 的名称. 假如调用的是函数指针, 那就返回它的 ID. */
    public abstract string get_name_of_callee();

    protected ArgUse[] _uargs;
    /** 调用表达式的参数列表, 由 use 组成. */
    public    ArgUse[]  uargs {
        get { return _uargs; }
        internal set { _uargs = value; }
    }
    public unowned Value? get_arg(uint index) {
        return index >= _uargs.length? null: _uargs[index].get_arg();
    }
    public void set_arg(uint index, Value? value) {
        if (likely(index < _uargs.length))
            _uargs[index].set_arg(value);
    }

    protected CallBase.C1_va_args(Value.TID    tid,
                                  OpCode       opcode,
                                  FunctionType callee_fn_type,
                                  int          arg_length) {
        base.C1(tid, opcode, callee_fn_type.return_type);
        this._callee_fn_type = callee_fn_type;

        if (callee_fn_type.is_var_args)
            arg_length = int.max(arg_length, callee_fn_type.params.length);
        this._uargs = new ArgUse[arg_length];
        for (uint i = 0; i < arg_length; i++)
            this._uargs[i] = new ArgUse.attach(this, i);
    }
    protected CallBase.C1_fixed_args(Value.TID tid, OpCode opcode, FunctionType callee_type)
    {
        base.C1(tid, opcode, callee_fn_type.return_type);
        this._callee_fn_type = callee_fn_type;
        int arg_length = callee_fn_type.params.length;
        this._uargs = new ArgUse[arg_length];
        for (uint i = 0; i < arg_length; i++)
            this._uargs[i] = new ArgUse.attach(this, i);
    }
    protected CallBase.C1_with_args(Value.TID    tid,
                                    OpCode       opcode,
                                    FunctionType callee_type,
                                    Value[]      args)
              requires (lengthof_args_fit_function(callee_type, args)) {
        base.C1(tid, opcode, callee_fn_type.return_type);
        this._callee_fn_type = callee_fn_type;
        int arg_length = callee_fn_type.params.length;
        this._uargs = new ArgUse[arg_length];
        for (uint i = 0; i < arg_length; i++) {
            this._uargs[i] = new ArgUse.attach(this, i) {
                usee = args[i]
            };
        }
    }
    class construct { _istype[TID.CALL_BASE] = true; }

    public static bool lengthof_args_fit_function(FunctionType fnty, Value[] args)
    {
        unowned Type[] fparams = fnty.params;
        if (args.length == fparams.length)
            return true;
        else if (fnty.is_var_args)
            return args.length > fparams.length;
        return false;
    }

    /** 表示参数的使用关系. */
    [CCode(cname="_ZN5Musys2IR8CallBase6ArgUseE")]
    public class ArgUse: Use {
        /** 参数所在 call 指令的索引(实例). */
        internal uint _index;
        /** 参数所在 call 指令的索引. */
        public uint index { get { return _index; } }

        /** 参数所在的 call 指令. */
        public new CallBase user {
            [CCode(cname="_ZN5Musys2IR8CallBase6ArgUse4userEg")]
            get { return static_cast<CallBase>(_user); }
        }

        internal Value _arg;
        public unowned Value? get_arg() { return _arg; }
        public void set_arg(Value? value)
        {
            Type? type_required = get_type_requirement();
            if (type_required == null)
                set_usee_always(ref _arg, value, this);
            else
                set_usee_type_match(type_required, ref _arg, value, this);
        }

        /** 这个参数是不是不受约束的变长参数. */
        public bool is_va_arg() {
            return index >= user.callee_fn_type.params.length;
        }
        /**
         * 检查这个参数是不是不受约束的变长参数. 倘若是, 就返回 null.
         * 否则返回这个参数的位置应有的参数类型.
         */
        public Type? get_type_requirement()
        {
            unowned var callee_fnty = user.callee_fn_type;
            unowned var fn_paramty  = callee_fnty.params;
            if (index >= fn_paramty.length)
                return null;
            return fn_paramty[index];
        }
        public override Value? usee {
            get { return get_arg(); } set { set_arg(value); }
        }

        public ArgUse.attach(CallBase parent, uint index) {
            this._index = index;
            attach_back(parent);
        }
    } // class ArgUse
} // class Musys.IR.CallBase
