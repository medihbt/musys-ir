namespace Musys.IR {
    public class Function: GlobalObject {
        public unowned FunctionType function_type {
            get { return (FunctionType)ptr_type.target; }
        }
        public unowned Type return_type {
            get { return function_type.return_type; }
        }

        protected FuncArg[] _args;

        [CCode(notify=false)]
        public FuncArg[] args { get { return _args; } }

        public FuncBody body{get;}

        public override void accept (IValueVisitor visitor) {
            visitor.visit_function (this);
        }
        public override bool is_mutable { get { return false; } set{} }
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

        public Function.as_extern(PointerType fty, string name)
        {
            base.C1(FUNCTION, fty, name, false);
            _init_head(fty);
        }
        public Function.as_impl(PointerType fty, string name)
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

        private void _init_head(PointerType fty)
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
            foreach (var b in _body)
                b.on_function_finalize();
            _body.clean();
        }
    }

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
