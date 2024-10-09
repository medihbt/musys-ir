namespace Musys.IR {
    /**
     * === 指针取索引指令 ===
     *
     * 把传入的指针 `source` 看作类型为 `collection_type[]` 数组, 按照
     * `indices[]` 数组所示的多级索引找到需要取的元素.
     *
     * 该指令表示指向这个元素的指针. 为展示所得指针指向的类型, 该指令实现了
     * IPointerStorage 接口.
     *
     * ==== 指令信息 ====
     *
     * ''操作数表'':
     * - `[0] = source`: 等待索引的源操作数指针
     * - `[1:] = indices[]`: 索引列表
     *
     * ''文法(Musys-IR)''
     *
     * {{{
     * %<id> = indexptr <primary-target-type>, ptr <source>, (<idx-type[i]> index[i])...
     * }}}
     *
     * - `primary-target-type`: 应当把 source 视为指向什么类型的指针.
     * - `source`: 源操作数指针
     * - `idx-type[0], index[0]`: 初始索引, 这时是把 source 当成 `primary-target-type[]` 数组指针.
     * - `idx-type[...], index[...]`: 后续分层索引. idx-type 必须是整数类型. 每层解索引之前的类型必须
     *   是数组、结构体或向量, 倘若是结构体的话则 index 必须是编译期常量.
     */
    public class IndexPtrSSA: Instruction, IPointerStorage {
        private SourceUse _usource;
        private Value     _source;
        /** 源操作数. 必须是指针类型的. */
        public  Value  source {
            get { return _source; }
            set {
                if (value == _source)
                    return;
                value_ptr_or_crash(value, "at IndexPtrSSA::source::set()");
                User.set_usee_always(ref _source, value, _usource);
            }
        }

        /** 初始被索引类型, 也就是被 index[0] 解包以后的类型. */
        public Type primary_target_type {
            get { return arr0_primary_target.element_type; }
            internal set {
                if (_arr0_primary_target != null &&
                    _arr0_primary_target.element_type == (!)value)
                    return;
                arr0_primary_target = value_type.type_ctx.get_array_type(value, 0);
            }
        }

        /** 隐藏的 0 长度数组类型, 这个类型加进去以后就不用担心 Use 要做额外检查的问题了. */
        public ArrayType arr0_primary_target { get; internal set; }

        internal IndexUse[] _indices;
        /** 索引列表. 其中 indices[0] 是初始索引. */
        public   IndexUse[]  indices { get { return _indices; } }

        public Value get_index_at(uint layer) throws RuntimeErr
        {
            if (layer >= indices.length)
                throw new RuntimeErr.INDEX_OVERFLOW("IndexPtrSSA(%d)[%u] overflow", id, layer);
            return indices[layer].index;
        }
        public void set_index_at(uint layer, Value? value)
                    throws RuntimeErr, Error
        {
            if (layer >= indices.length)
                throw new RuntimeErr.INDEX_OVERFLOW("IndexPtrSSA(%d)[%u] overflow", id, layer);
            IndexUse uindex = indices[layer];
            uindex.set_usee_throws(value);
        }

        public Type get_ptr_target() {
            return indices[indices.length - 1].type_after_extract;
        }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_index_ptr(this);
        }

        /* 析构过程 */
        private void _delete_indicies()
        {
            foreach (IndexUse u in indices)
                u.index = null;
            _indices = null;
        }
        public override void on_function_finalize() {
            value_fast_clean(ref _source, _usource);
            _delete_indicies();
            base._fast_clean();
        }
        public override void on_parent_finalize() {
            value_deep_clean(ref _source, _usource);
            _delete_indicies();
            base._deep_clean();
        }

        private IndexPtrSSA._full_empty(ArrayType arr0_primary_target)
        {
            base.C1(INDEX_PTR_SSA, INDEX_PTR,
                    arr0_primary_target.type_ctx.get_opaque_ptr());
            this.arr0_primary_target = arr0_primary_target;
        }
        private void _init_uses(owned IndexUse[] indices)
        {
            /* `[0] = source` */
            this._usource = new SourceUse();
            this._usource.attach_back(this);

            /* `[1:] = indices[]` */
            this._indices = (owned)indices;
            foreach (IndexUse i in _indices)
                i.attach_back(this);
        }
        public IndexPtrSSA.move_nocheck(Type primary_target, owned IndexUse[] indices)
        {
            base.C1(INDEX_PTR_SSA, INDEX_PTR,
                    primary_target.type_ctx.get_opaque_ptr());
            this.primary_target_type = primary_target;
            this._init_uses((owned)indices);
        }
        public IndexPtrSSA.move(Type primary_target, owned IndexUse[] indices)
        {
            ArrayType arr0 = primary_target
                            .type_ctx
                            .get_array_type(primary_target, 0);
            this._full_empty(arr0);

            uint layer = 0;
            Type curr  = arr0;
            foreach (IndexUse u in indices) {
                u.layer = layer;
                if (_check_index_stepu(u, curr))
                    break;
                curr = u.type_after_extract; layer++;
            }
            this._init_uses((owned)indices);
        }
        public IndexPtrSSA.from_values(Type primary_target, Gee.List<Value> indices)
                    throws TypeMismatchErr, IndexPtrErr
        {
            ArrayType arr0 = primary_target
                            .type_ctx
                            .get_array_type(primary_target, 0);
            this._full_empty(arr0);

            var  uses = new IndexUse[indices.size];
            uint layer_idx = 0;
            Type curr = arr0;
            foreach (Value? index in indices) {
                if (check_type_index_step(index, layer_idx, curr, out curr)) {
                    crash_fmt(Musys.SourceLocation.current(),
                        "Iteration (%u / %d) terminates too early",
                        layer_idx, uses.length);
                }
                uses[layer_idx] = new IndexUse() {
                    user  = this,
                    layer = layer_idx,
                    type_after_extract = curr,
                    usee  = index
                };
                layer_idx++;
            }
            _init_uses((owned)uses);
        }
        public IndexPtrSSA.from_value_array(Type primary_target, Value source, Value[] indices)
                    throws TypeMismatchErr, IndexPtrErr {
            this.from_values(primary_target, new GeeArraySlice<Value>.from(indices));
            this.source = source;
        }

        class construct {
            _istype[TID.IPOINTER_STORAGE] = true;
            _istype[TID.INDEX_PTR_SSA]    = true;
        }

        /**
         * 迭代函数: 检查传入的 index 是否匹配解包前的类型 before_extracted
         *
         * @return 迭代函数返回值, true 表示终止迭代, false 表示继续迭代.
         */
        private static bool _check_index_stepu(IndexUse u, Type before_extracted)
        {
            try {
                Type after_extarcted = null;
                bool ret = check_type_index_step(u.index, u.layer,
                        before_extracted, out after_extarcted);
                u.type_after_extract = after_extarcted;
                return ret;
            } catch (Error e) {
                crash_err(e);
            }
        }

        /** 表示源操作数的使用关系 */
        public class SourceUse: Use {
            public new IndexPtrSSA user {
                get { return static_cast<IndexPtrSSA>(_user); }
            }
            public override Value? usee {
                get { return user._source; } set { user.source = value; }
            }
        }

        /** 表示索引操作数的使用关系 */
        public class IndexUse: Use {
            /** 索引层, 从 0 计数. */
            public uint layer { get; internal set; }

            /** 本层取索引前的类型 */
            public unowned Type type_before_extract {
                get {
                    if (layer == 0)
                        return user.arr0_primary_target;
                    return user.indices[layer - 1].type_after_extract;
                }
            }
            /** 本层取索引后的类型 */
            public unowned Type type_after_extract { get; internal set; }

            public new IndexPtrSSA user {
                get { return static_cast<IndexPtrSSA>(_user); }
                set { _user = value; }
            }

            internal Value _index;
            /** 本层索引. 当未解包的类型是结构体时, 本层索引不可变. */
            public Value index {
                get { return _index; }
                set {
                    if (value == _index)
                        return;
                    if (value != null && !value.value_type.is_int) {
                        crash_fmt(Musys.SourceLocation.current(),
                            "IndexPtrSSA(%d)::IndexUse(layer %u).index requires int type, " +
                            "but got %s",
                            user.id, layer, value.value_type.name);
                    }
                    User.replace_use(_index, value, this);
                    _index = value;
                }
            }
            /**
             * 本层索引是否可变.
             * 倘若该方法返回 true, 那 index 一定是常数, 否则该指令不是完备的.
             */
            public bool index_mutable()
            {
                if (layer == 0)
                    return true;
                Type before_extract = type_before_extract;
                if (!before_extract.is_aggregate)
                    return false;
                return ((AggregateType)before_extract).element_always_consist;
            }
            public override Value? usee {
                get { return _index; }
                set {
                    index = value;
                    if (error != null)
                        return;
                }
            }

            public IndexUse.auto_attach(IndexPtrSSA user, uint layer, Type after_extracted) {
                this.user  = user;
                this.layer = layer;
                this.type_after_extract = after_extracted;
                this.attach_back(user);
            }
        }
    }

    /**
     * 在 `IndexPtrSSA` 中遇到的各种问题.
     * @see Musys.IR.IndexPtrSSA
     */
    public errordomain IndexPtrErr {
        /** 索引是常量值, 但是溢出了 */
        INDEX_OVERFLOW,

        /** 索引是用来解包结构体的, 但你传入的却不是整数常量值 */
        INDEX_NOT_CONSTANT,

        /** 索引是用来解包结构体的, 但你却要改变它 */
        SET_IMMUTABLE_INDEX;
    }
}