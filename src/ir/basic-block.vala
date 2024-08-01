namespace Musys.IR {
    public class BasicBlock: Value {
        internal         BasicBlock _next;
        internal unowned BasicBlock _prev;
        internal unowned FuncBody   _list;

        public BasicBlock unplug()
        {
            BasicBlock othis = this;
            _prev._next = _next;
            _next._prev = _prev;
            return othis;
        }
        public void on_function_finalize()
        {
            if (instructions == null)
                return;
            foreach (var i in instructions)
                i.on_function_finalize();
            instructions.clean();
        }

        public weak Function parent{get;set;}

        internal InstructionList _instructions;
        public   InstructionList  instructions {
            get { return _instructions; }
        }
        public IBasicBlockTerminator terminator{get;set;}

        public override void accept(IValueVisitor visitor) {
            visitor.visit_basicblock (this);
        }
        internal BasicBlock.raw(TypeContext tctx) {
            base.C1(BASIC_BLOCK, tctx.label_type);
            _instructions = null;
        }
        public BasicBlock.with_unreachable(TypeContext tctx) {
            base.C1(BASIC_BLOCK, tctx.label_type);
            _instructions = new InstructionList.empty(this);
            _instructions.append(
                new UnreachableSSA(this)
            );
        }
        public BasicBlock.with_terminator(owned IBasicBlockTerminator termoinator)
        {
            var tctx = terminator.value_type.type_ctx;
            base.C1(BASIC_BLOCK, tctx.label_type);
            _instructions = new InstructionList.empty(this);
            _instructions.append(terminator);
            this.terminator = terminator;
        }
        ~BasicBlock() {
            if (instructions == null || instructions.is_empty())
                return;
            foreach (var i in instructions)
                i.on_parent_finalize();
            instructions.clean();
        }

        [CCode(cname="_ZN5Musys2IR10BasicBlock8ReadFuncE")]
        public delegate bool        ReadFunc   (BasicBlock value);

        [CCode(cname="_ZN5Musys2IR10BasicBlock11ReplaceFuncE")]
        public delegate BasicBlock? ReplaceFunc(BasicBlock value);
    }
}
