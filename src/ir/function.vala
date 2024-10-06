namespace Musys.IR {
    /** 
     * ### 函数声明或函数定义
     *
     * Function 是典型的使用者-操作数结合体, 既可以当成 call 指令的函数指针
     * 操作数, 也可以作为基本块的容器.
     *
     * 由于函数类型不可实例化, Function 作为操作数时, 它的类型是 **函数指针
     * 类型** 而不是函数类型. 例如, 函数 `i32 main(i32 %argc, i8** %argv)`
     * 的类型是 `ptr` 而不是 `i32(i32, i8**)`. 由于 Musys 的指针是不透明的,
     * 因此 Function 和它的父类 GlobalObject 一样实现了 IPointerValue 接口.
     * 你可以通过 `function_type` 获取对应的函数类型.
     *
     * 上面所示的 `define/declare i32 main(i32 %0, i8** %1)` 这样的内容称为
     * 函数头, 它是函数得以成为 Value 的重要结构. 函数头记录了函数类型、参数列表
     * 等等, 还提供了一些可以快速获取返回类型等的工具方法.
     *
     * 有些函数没有函数体, 文本格式以 "declare" 修饰, 这时函数是 "函数声明";
     * 其他有函数体的函数就称为 "函数定义". 函数定义仅仅比函数声明多了一个函数体,
     * 为了实现方便, Function 类同时承担表示这两种函数语法的作用.
     *
     * - 要区分一个函数是不是函数声明, 你需要 `is_extern` 只读布尔属性.
     * - 倘若你想把一个函数定义变成函数声明, 请调用 `disable_impl` 方法.
     * - 倘若你想把一个函数声明变成函数定义, 请调用 `enable_impl` 方法.
     */
    public class Function: GlobalObject {
        public unowned FunctionType function_type {
            get { return static_cast<FunctionType>(content_type); }
        }
        public unowned Type return_type {
            get { return function_type.return_type; }
        }

        protected FuncArg[] _args;

        /** 函数参数列表 */
        [CCode(notify=false)]
        public FuncArg[] args { get { return _args; } }

        /**
         * #### 函数体
         *
         * 可以是 null. 函数体为空时表示这个函数是函数声明, 否则是函数定义.
         */
        public FuncBody? body { get; internal set; }

        public override void accept(IValueVisitor visitor) {
            visitor.visit_function(this);
        }

        /** 函数体处于只读数据区, 永远不可变. 倘若这玩意可变, 那做个毛线优化. */
        public override bool is_mutable {
            get { return false; }
            set {
                if (value == false)
                    return;
                warning("Blocked: try to make function {@%s} mutable.", name);
            }
        }
        /** 函数体为空时表示这个函数是函数声明, 否则是函数定义. */
        public override bool is_extern { get { return body == null; } }

        public override bool enable_impl()
        {
            if (!is_extern)
                return false;
            _init_body();
            return true;
        }
        public override bool disable_impl()
        {
            if (is_extern)
                return false;
            _clean_body();
            return true;
        }

        public Function.as_extern(NamedPointerType fty, string name)
        {
            base.C1(FUNCTION, fty, name, false);
            _init_head(fty);
        }
        public Function.as_impl(NamedPointerType fty, string name)
        {
            base.C1(FUNCTION, fty, name, false);
            this._init_head(fty);
            this._init_body();
        }
        class construct { _istype[TID.FUNCTION] = true; }

        ~Function() {
            if (body != null)
                this._clean_body();
        }

        private void _init_head(NamedPointerType fty)
        {
            Type target = fty.target;
            if (!target.is_function)
                crash(@"Function value type requires 'Pointer to Function type', but now it is $(fty)");
            var ftarget = (FunctionType)target;
            unowned var params = ftarget.params;
            _args = new FuncArg[params.length];
            for (int i = 0; i < _args.length; i++)
                _args[i] = new FuncArg (params[i], this);
        }
        private void _init_body()
        {
            var tctx = value_type.type_ctx;
            var retval = create_zero_or_undefined(return_type);
            var retssa = new ReturnSSA(retval);
            var retblk = new BasicBlock.with_terminator(retssa);
            var fnbody = new FuncBody.empty(tctx, this);
            fnbody.append_as_entry(retblk);
            this._body = (owned)fnbody;
        }
        private void _clean_body()
        {
            unowned var body = (!)this._body;
            foreach (var b in body)
                b.on_function_finalize();
            _body.clean();
            _body = null;
        }
    }

    /**
     * ### 函数参数
     *
     * 简单的函数参数类. 用于存放参数的类型, 函数作为定义时, 参数就变成一个只读的存取媒介.
     */
    public class FuncArg: Value {
        public override void accept (IValueVisitor visitor) {
            visitor.visit_argument(this);
        }
        public weak Function parent{get;set;}

        public FuncArg(Type type, Function parent)
        {
            base.C1(FUNC_ARG, type);
            this.parent = parent;
        }
        class construct { _istype[TID.FUNC_ARG] = true; }
    }

    /**
     * ### 函数体
     *
     * 函数定义必需的结构, 本质上就是一个基本块集合. 在 Musys-IR 中, 这个集合因为
     * 效率需要被实现为一条链表.
     *
     * 函数调用发生以后, 执行流总会从一个基本块进入, 该基本块称为函数的**入口**(对应
     * 读写属性 `entry`).
     *
     * 大多数函数都有一个或者几个出口基本块, 但是 Function 没有专门的属性来存储这些
     * 基本块.
     */
    public class FuncBody {
        internal BasicBlock _node_begin;
        internal BasicBlock _node_end;

        public weak Function    parent;
        public weak TypeContext type_ctx;
        public weak BasicBlock  entry;
        public size_t length{get;internal set;default = 0;}

        public FuncBody.empty(TypeContext tctx, Function parent)
        {
            _node_begin = new BasicBlock.raw(tctx.label_type);
            _node_end   = new BasicBlock.raw(tctx.label_type);
            _node_begin._next = _node_end;
            _node_end._prev = _node_begin;
            _node_begin._list = this;
            _node_end._list   = this;
            this.type_ctx = tctx;
            this.parent  = parent;
        }
        internal void append_raw(BasicBlock block)
        {
            var prev = _node_end._prev;
            block._next     = _node_end;
            block._prev     = prev;
            block._list     = this;

            prev._next      = block;
            _node_end._prev = block;
            _length++;
        }
        internal void append_as_entry(BasicBlock block)
        {
            this.entry = block;
            append_raw(block);
        }
        public Iterator iterator() { return {_node_begin}; }
        public void clean()
        {
            _node_end._prev = _node_begin;
            _node_begin._next = _node_end;
        }

        public struct Iterator {
            public         BasicBlock block;
            public unowned FuncBody   list {
                get { return block._list; }
            }
            public unowned BasicBlock get() { return block; }
            public bool next()
            {
                if (block == null)
                    crash("Block is NULL!", true, {Log.FILE, Log.METHOD, Log.LINE});
                if (block._next == null || block == list._node_end)
                    return false;
                block = block._next;
                if (block._next == null || block == list._node_end)
                    return false;
                return true;
            }
        }
    }
}
