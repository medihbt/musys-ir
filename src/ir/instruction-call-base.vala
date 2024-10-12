/**
 * === 调用类指令(基类) ===
 *
 * 一切有函数调用结构的指令——调用类指令. 通常来说, 只要存在 `xxx(a, b, c)` 这种
 * 结构的指令都可以算调用类指令.
 *
 * 每个调用类指令都有一个函数类型 `callee_fn_type` 作为约束. 对于有实际函数的调用
 * 指令(如 call, vcall, invoke), `callee_fn_type` 就是对应的函数类型. 其他指令
 * (如 intrin) 就不是了, 它们的函数类型是随着指令本身生成的.
 *
 * 调用类指令都有''被调用者'', 即属性 `callee`. 为方便管理, 被调用者都是值, 就算
 * 内联汇编函数也要算作特殊的全局函数. 被调用者的使用关系是 `CalleeUse`.
 *
 * 调用类指令都有''参数列表'', 即属性 `uargs`. 参数信息的类型是 `ArgUse`, 兼任
 * 数据流图边和函数参数信息两个角色. 鉴于 C-ABI 的那种变长参数在什么平台上都是既
 * 不安全也不跨平台的坏文明, 因此在 Musys-IR 中不论函数类型还是函数调用语句都不支
 * 持运行期变长参数. 至于 Musys 前端该用什么语法糖把它圆回来, 那就不是 IR 要管的了.
 *
 * ==== 父类的操作数表 ====
 *
 * * `[0] = callee`: 被调用的函数值
 * * `[1:] = args[]`: 函数的参数
 */
public abstract class Musys.IR.CallBase: Instruction {
    protected unowned FunctionType _callee_fn_type;
    /** 调用者的函数类型, 即这条指令的参数类型约束. */
    public    unowned FunctionType  callee_fn_type {
        get { return _callee_fn_type; }
        internal set { _callee_fn_type = value; }
    }

    /**
     * ==== 被当作函数调用的值 ====
     *
     * ''在实际发生函数调用的指令中, callee 一定是函数指针''. 但是遇到 intrin
     * 这种伪装成函数调用的拓展指令时就是那个 intrin 指令说了算了. 一般来说也是
     * 指针, 也有可能就是被当成函数调用的函数类型.
     */
    public Value callee {
        get { return _callee; }
        set {
            try { _check_callee(callee); }
            catch (Error e) { crash_err(e); }
            User.set_usee_always(ref _callee, value, _ucallee);
        }
    }
    protected Value     _callee;
    protected CalleeUse _ucallee;
    protected virtual void _check_callee(Value? callee) throws Error {}
    /** callee 的名称. 假如调用的是函数指针, 那就返回它的 ID. */
    public virtual string get_name_of_callee()
    {
        if (_callee == null)
            return "<null callee>";
        if (callee is GlobalObject)
            return ((GlobalObject)callee).name;
        return callee.id.to_string();
    }

    protected ArgUse[] _uargs;
    /** 调用表达式的参数列表, 由 use 组成. */
    public    ArgUse[]  uargs {
        get                { return  _uargs; }
        internal owned set { _uargs = value; }
    }
    /** 获取位于 index 位置的参数值. 倘若 index 溢出, 则返回 null. */
    public unowned Value? get_arg(uint index) {
        return index >= _uargs.length? null: _uargs[index].arg;
    }
    /** 把 index 位置的参数值修改为 value. 倘若 index 溢出, 则什么都不做. */
    public void set_arg(uint index, Value? value) {
        if (likely(index < _uargs.length))
            _uargs[index].arg = value;
    }

    private void _delete_arguments()
    {
        for (int i = 0; i < _uargs.length; i++) {
            ArgUse uarg = (owned)(uargs[i]);
            uarg.arg = null;
            uarg.remove_this();
        }
        _uargs = null;
    }
    public override void on_parent_finalize()
    {
        _delete_arguments();
        callee = null;
        base.on_parent_finalize();
    }
    public override void on_function_finalize()
    {
        _delete_arguments();
        callee = null;
        base.on_function_finalize();
    }

    protected CallBase.C1(Value.TID tid, OpCode opcode, FunctionType callee_type)
    {
        base.C1(tid, opcode, callee_type.return_type);
        this._callee_fn_type = callee_type;
        int arg_length = callee_type.params.length;

        /* [0] = callee */
        this._ucallee = new CalleeUse();
        this._ucallee.attach_back(this);

        /* [1:] = args[] */
        this._uargs = new ArgUse[arg_length];
        for (uint i = 0; i < arg_length; i++)
            this._uargs[i] = new ArgUse.attach(this, i);
    }
    protected CallBase.C1_with_args(Value.TID    tid,
                                    OpCode       opcode,
                                    FunctionType callee_type,
                                    Gee.List<Value> args)
              requires (callee_type.params.length == args.size) {
        this.C1(tid, opcode, callee_type);
        int index = 0;
        foreach (Value? a in args) {
            _uargs[index] = new ArgUse.attach(this, index) { arg = a };
            index++;
        }
    }
    class construct { _istype[TID.CALL_BASE] = true; }

    /** 表示参数的使用关系. */
    public class ArgUse: Use {
        /** 参数所在 call 指令的索引. */
        public uint index { get; internal set; }

        /** 参数所在的 call 指令. */
        public new CallBase user {
            get { return static_cast<CallBase>(_user); }
            internal set { _user = value; }
        }

        internal Value _arg;
        /** 此参数位置上的参数值 */
        public   Value  arg {
            get { return _arg; }
            set {
                set_usee_type_match(get_type_requirement(),
                    ref _arg, value, this);
            }
        }

        /** 这个参数的位置应有的参数类型. */
        public Type get_type_requirement() {
            return user.callee_fn_type.params[index];
        }
        public override Value? usee {
            get { return arg; } set { arg = value; }
        }

        public ArgUse.attach(CallBase parent, uint index) {
            this.index = index;
            attach_back(parent);
        }
    } // class ArgUse

    protected class CalleeUse: Use {
        public new CallBase user {
            get { return (CallBase)_user; }
            set { _user = value; }
        }
        public override Value? usee {
            get { return user.callee; }
            set { user.callee = value; }
        }
    }
} // class Musys.IR.CallBase
