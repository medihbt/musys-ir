namespace Musys.IR {
    public abstract class ConstIndexPtrBase: ConstExpr {
        public IndexUse[] indices { get; internal owned set; }

        public void verify() throws TypeMismatchErr, IndexPtrErr
        {
            int prev = 0;
            int len  = indices.length;
            while (prev < len - 1) {
                int layer = prev + 1;
                unowned IndexUse luse  = indices[layer], puse  = indices[prev];
                unowned Type     ltype = luse.elem_type, ptype = puse.elem_type;
                unowned Constant lidx = luse.get();
                Type? after_extract = null;
                check_type_index_step(lidx, layer, ptype, out after_extract);
                type_match_or_throw(after_extract, ltype, "indices[%d]", layer);
                prev = layer;
            }
        }
        public unowned Type get_primary_type() {
            return indices[0].elem_type;
        }

        protected void _reg_move_index_uses(owned IndexUse[] indices) {
            foreach (var u in indices)
                u.attach_back(this);
            this._indices = (owned)indices;
        }
        protected IndexUse[] _index_values_to_use(Type primary, Gee.List<Constant> indices)
            throws TypeMismatchErr, IndexPtrErr
        {
            var uses  = new IndexUse[indices.size];
            int layer = 0;
            Type before_extract = primary;
            Type after_extract  = primary;
            foreach (var c in indices) {
                uses[layer] = new IndexUse() {
                    layer     = layer,
                    elem_type = after_extract,
                    usee      = c,
                };
                before_extract = after_extract;
                check_type_index_step(c, layer, before_extract, out after_extract);
                layer++;
            }
            return uses;
        }
        protected ConstIndexPtrBase.C1(Value.TID tid, Type type) {
            base.C1(tid, type);
        }
        protected ConstIndexPtrBase.C1_ptr_move(Value.TID tid, Constant ptr_src, owned IndexUse[] indices) {
            value_ptr_or_crash(ptr_src);
            this.C1(tid, static_cast<PointerType>(ptr_src.value_type));
            _reg_move_index_uses((owned)indices);
        }

        class construct {
            _istype[TID.CONST_INDEX_PTR_BASE] = true;
        }

        public class IndexUse: Use {
            public uint layer     { get; internal set; }
            public Type elem_type { get; internal set; }

            internal Constant _index;
            public unowned Constant @get() { return _index; }
            public void @set(Constant value) throws TypeMismatchErr
            {
                value_int_or_throw(value, "ConstIndexExpr()[%u]", layer);
                if (unlikely(_index == value))
                    return;
                User.replace_use(_index, value, this);
                _index = value;
            }

            public override Value? usee {
                get { return this.get(); }
                set {
                    assert(value is Constant);
                    try { this.set(static_cast<Constant>(value)); }
                    catch (TypeMismatchErr e) { crash_err(e, ""); }
                }
            }
        } // class IndexUse

        public enum IndexKind { AGGREGATE, PTR }
    } // class ConstIndexBase


    /** e.g. ``getelementptr {i32, i32, i64, i8, [3 x i8]}, ptr @val, i32 0, i64 1`` */
    public class ConstIndexPtrExpr: ConstIndexPtrBase {
        public override bool is_zero { get { return false; } }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_const_index_ptr(this);
        }

        protected Constant    _source;
        protected unowned Use _usource;
        public Constant source {
            get { return _source; }
            set {
                value_ptr_or_crash(value);
                User.replace_use(_source, value, _usource);
                _source = value;
            }
        } // public Constant source

        public ConstIndexPtrExpr.raw(PointerType ptr_ty) {
            base.C1(CONST_INDEX_PTR, ptr_ty);
        }
        public ConstIndexPtrExpr.raw_move(Constant source, owned IndexUse[] indices)
            throws TypeMismatchErr {
            value_ptr_or_crash(source);
            this.raw(static_cast<PointerType>(source));
            this.source = source;
            this._reg_move_index_uses((owned)indices);
        }
        public ConstIndexPtrExpr.checked(Constant source, owned IndexUse[] indices)
            throws TypeMismatchErr, IndexPtrErr {
            this.raw_move(source, (owned)indices);
            this.verify();
        }
        public ConstIndexPtrExpr.from_values(Constant source, Type primary, Gee.List<Constant> indices)
            throws TypeMismatchErr, IndexPtrErr {
            this.raw_move(source, base._index_values_to_use(primary, indices));
        }

        class construct {
            _istype[TID.CONST_INDEX_PTR] = true;
        }

        protected sealed class SourceUse: Use {
            public new ConstIndexPtrExpr user {
                get { return static_cast<ConstIndexPtrExpr>(_user); }
                set { _user = value; }
            }
            public override Value? usee {
                get { return user._source; }
                set {
                    if (value == null) {
                        user.source = null; return;
                    }
                    assert(value.isvalue_by_id(CONSTANT));
                    user.source = static_cast<Constant>(value);
                }
            }
        } // sealed class SourceUse

    } // class IndexPtrExpr


    /**
     * === 类型偏移量计算表达式 ===
     *
     * ``offsetof {i32, i32, i64, i8, [3 x i8]}, i32 0, i64 1``
     */
    public class ConstOffsetOfExpr: ConstIndexPtrBase {
        public override bool is_zero { get { return false; } }
        public override void accept(IValueVisitor visitor) {
            visitor.visit_const_offset_of(this);
        }

        public ConstOffsetOfExpr.raw(TypeContext tctx) {
            base.C1(CONST_OFFSET_OF, tctx.get_intptr_type());
        }
        public ConstOffsetOfExpr.raw_move(owned IndexUse[] indices) {
            assert(indices.length >= 1);
            this.raw(indices[0].elem_type.type_ctx);
            base._reg_move_index_uses((owned)indices);
        }
        public ConstOffsetOfExpr.checked(owned IndexUse[] indices)
            throws TypeMismatchErr, IndexPtrErr {
            this.raw_move((owned)indices);
            this.verify();
        }
        public ConstOffsetOfExpr.from_values(Type primary, Gee.List<Constant> indices)
            throws TypeMismatchErr, IndexPtrErr {
            this.raw_move(_index_values_to_use(primary, indices));
        }

        class construct {
            _istype[TID.CONST_OFFSET_OF] = true;
        }
    } // class OffsetOfExpr
} // namespace Musys.IR