namespace Musys.IRUtil {
    public class ValueRefEqualJudge: Object, IR.IValueVisitor {
        public   bool retval;
        internal IR.Value lhs;
        internal IR.Value rhs;

        public bool judge_equals(IR.Value lhs, IR.Value rhs)
        {
            if (lhs == rhs)
                return true;
            if (lhs.get_class() != rhs.get_class() ||
                !lhs.value_type.equals(rhs.value_type))
                return false;
            if (lhs.shares_ref && rhs.shares_ref) {
                this.lhs = lhs;
                this.rhs = rhs;
                lhs.accept(this);
                return retval;
            }
            return false;
        }
        public override void visit_const_int(IR.ConstInt ival) {
            var irhs = static_cast<IR.ConstInt>(rhs);
            retval = (irhs.apint_value == ival.apint_value);
        }
        public override void visit_const_float(IR.ConstFloat value) {
            var frhs = static_cast<IR.ConstFloat>(rhs);
            retval = (frhs.f64_value == value.f64_value);
        }
        public override void visit_const_data_zero(IR.ConstDataZero value) { retval = true; }
        public override void visit_ptr_null       (IR.ConstPtrNull  value) { retval = true; }
        public override void visit_array_expr(IR.ArrayExpr value)
        {
#       if MUSYS_DO_ARRAY_COMPRESS
            var arhs = static_cast<IR.ArrayExpr>(rhs);
            if (arhs._elems == null) {
                retval = value.is_zero;
                return;
            }
            if (value._elems == null) {
                retval = arhs.is_zero;
                return;
            }
            unowned var lelems = value._elems;
            unowned var relems = arhs._elems;
            for (uint i = 0; i < lelems.length; i++) {
                if (judge_equals(lelems[i], relems[i]))
                    continue;
                retval = false;
                return;
            }
            retval = true;
#       else
            retval = false;
#       endif
        }
        public override void visit_undefined(IR.UndefinedValue udef) {
            var urhs = static_cast<IR.UndefinedValue>(rhs);
            retval = udef.is_poisonous == urhs.is_poisonous;
        }
    }

    public class ValueRefHasher: Object, IR.IValueVisitor {
        public size_t hashval;
        public bool  mappable;
        public IR.Value value;

        public size_t hash(IR.Value value)
        {
            if (this.value == value)
                return hashval;
            this.value = value;

            if (
#       if !MUSYS_DO_ARRAY_COMPRESS
                value.isvalue_by_id(ARRAY_EXPR) ||
#       endif
                !value.shares_ref) {
                this.mappable = false;
                this.hashval  = (size_t)int64_hash((intptr)value);
                return hashval;
            }
            value.accept(this);
            this.mappable = true;
            return hashval;
        }
        public uint hash32(IR.Value value) {
            return (uint)hash(value);
        }

        public override void visit_const_int(IR.ConstInt value)
        {
            hashval = hash_combine3(
                value.tid,
                value.value_type.hash(),
                (size_t)value.apint_value.u64_value
            );
        }
        public override void visit_const_float(IR.ConstFloat value)
        {
            hashval = hash_combine3(
                value.tid,
                value.value_type.hash(),
                double_hash(value.f64_value)
            );
        }
        public override void visit_const_data_zero(IR.ConstDataZero value) {
            hashval = hash_combine2(value.tid, value.value_type.hash());
        }
        public override void visit_ptr_null(IR.ConstPtrNull value) {
            hashval = hash_combine2(value.tid, value.value_type.hash());
        }
        public override void visit_array_expr(IR.ArrayExpr value)
        {
#       if MUSYS_DO_ARRAY_COMPRESS
            IR.Constant z     = null;
            size_t zhash      = 0;
            bool   value_zero = false;
            if (value._elems == null) {
                value_zero = true;
                z = IR.create_zero_or_undefined(value.array_type.element_type);
                zhash = hash(z);
            }
            unowned var elems = value.elems;
            size_t elemlen = value.array_type.element_number;

            hashval = hash_combine2(value.tid, value.array_type.hash());
            for (uint i = 0; i < elemlen; i++) {
                if (!value_zero) {
                    z = elems[i];
                    zhash = hash(z);
                }
                hashval = hash_combine2(hashval, zhash);
            }
#       else
            hashval = int64_hash((intptr)value);
#       endif
        }
    }

    public class ValueRefCompressor: Object {
        private Gee.HashMap<unowned IR.Value, IR.Value> _value_map;
        private ValueRefHasher     _hasher;
        private ValueRefEqualJudge _eq_judge;

        public MapResult map_value(IR.Value value)
        {
            _hasher.hash(value);
            if (!_hasher.mappable)
                return {value, false};
            if (_value_map.has_key(value))
                return {_value_map[value], true};
            _value_map[value] = value;
            return {value, true};
        }

        public void compress_module(IR.Module module)
        {
            foreach (var ent in module.global_def) {
                var gdef = ent.value;
                if (gdef.isvalue_by_id(FUNCTION))
                    _do_compress_function(static_cast<IR.Function>(gdef));
                else if (gdef.isvalue_by_id(GLOBAL_VARIABLE))
                    _do_compress_gvar(static_cast<IR.GlobalVariable>(gdef));
            }
            _value_map.clear();
        }
        public void compress_function(IR.Function fn) {
            _do_compress_function(fn);
            _value_map.clear();
        }
        public void compress_basicblock(IR.BasicBlock bb) {
            _do_compress_basicblock(bb);
            _value_map.clear();
        }
        private void _do_compress_gvar(IR.GlobalVariable gvar)
        {
            if (gvar.is_extern ||
               !gvar.ptr_type.target.is_valuetype)
                return;
            MapResult new_mapped = map_value(gvar.init_content);
            if (!new_mapped.mappable ||
                new_mapped.mapped == null)
                return;
            if (new_mapped.mapped is IR.Constant)
                gvar.init_content = static_cast<IR.Constant>(new_mapped.mapped);
        }
        private void _do_compress_function(IR.Function fn)
        {
            if (fn.is_extern)
                return;
            foreach (var bb in fn.body)
                _do_compress_basicblock(bb);
        }
        private void _do_compress_basicblock(IR.BasicBlock bb)
        {
            foreach (var inst in bb.instructions)
                _do_compress_instruction(inst);
        }
        private void _do_compress_instruction(IR.Instruction inst)
        {
            foreach (var use in inst.operands) {
                MapResult new_usee = map_value(use.usee);
                if (!new_usee.mappable)
                    return;
                IR.Value? v = new_usee.mapped;
                if (v != null)
                    use.usee = v;
            }
        }

        public ValueRefCompressor() {
            _hasher   = new ValueRefHasher();
            _eq_judge = new ValueRefEqualJudge();
            _value_map = new Gee.HashMap<unowned IR.Value, IR.Value>(
                _hasher.hash32,
                _eq_judge.judge_equals,
                _eq_judge.judge_equals
            );
        }

        public struct MapResult {
            IR.Value  mapped;
            stdc.bool mappable;
        }
    }
} // namespace Musys.IRUtil
