namespace Musys.IR {
    public class CastSSA: UnarySSA {
        public Value source {
            get { return _operand; } set { operand = value; }
        }
        public unowned Type source_type{ get { return _operand_type; } }

        public override void accept(IValueVisitor visitor) {
            visitor.visit_inst_cast(this);
        }

        public CastSSA.raw(OpCode opcode, Type target_type, Type source_type) {
            base.C1(CAST_SSA, opcode, target_type, source_type);
        }
        public CastSSA.nocheck(OpCode opcode, Type target_type, Value source) {
            this.raw(opcode, target_type, source.value_type);
            this.source = source;
        }
        public CastSSA.as_itof(FloatType target_type, Value source, bool is_signed = true)
                    throws TypeMismatchErr {
            value_int_or_throw(source, "CastSSA::as_itof()::source");
            var opcode = is_signed ? OpCode.SITOFP: OpCode.UITOFP;
            this.nocheck(opcode, target_type, source);
        }
        public CastSSA.as_ftoi(IntType target_type, Value source)
                    throws TypeMismatchErr {
            value_float_or_throw(source, "CastSSA::as_ftoi()::source");
            this.nocheck(FPTOSI, target_type, source);
        }
        public CastSSA.as_itoi(IntType target_type, Value source, bool is_signed = true)
                    throws TypeMismatchErr {
            IntType ity = value_int_or_throw(source, "CastSSA::as_itoi()::source");
            var sbit = ity.binary_bits;
            var tbit = target_type.binary_bits;
            OpCode opcode;
            if (tbit > sbit)
                opcode = is_signed ? OpCode.SEXT: OpCode.ZEXT;
            else if (tbit == sbit)
                opcode = OpCode.BITCAST;
            else
                opcode = TRUNC;
            this.nocheck(opcode, target_type, source);
        }
        public CastSSA.as_ftof(FloatType target_type, Value source)
                    throws TypeMismatchErr {
            FloatType sfty = value_float_or_throw(source, "CastSSA::as_itoi()::source");
            var sbit = sfty.binary_bits;
            var tbit = target_type.binary_bits;
            var opcode = tbit >= sbit? OpCode.FPEXT: OpCode.FPTRUNC;
            this.nocheck(opcode, target_type, source);
        }
        public CastSSA.as_bitcast(Type target_type, Value source)
                    throws TypeMismatchErr {
            if (!target_type.is_instantaneous) {
                throw new TypeMismatchErr.NOT_INSTANTANEOUS(
                    @"at CastSSA::as_bitcast: $target_type does not make an instance");
            }
            type_bit_same_or_throw(source.value_type, target_type);
            this.nocheck(BITCAST, target_type, source);
        }
        public CastSSA.as_itop(PointerType target_type, Value source)
                    throws TypeMismatchErr {
            value_int_or_throw(source, "CastSSA.as_itop()::source");
            this.nocheck(INT_TO_PTR, target_type, source);
        }
        public CastSSA.as_ptoi(IntType target_type, Value source)
                    throws TypeMismatchErr {
            value_ptr_or_throw(source, "CastSSA.as_ptoi()::source");
            this.nocheck(PTR_TO_INT, target_type, source);
        }
        public CastSSA.as_ptoi_auto(Value source)
                    throws TypeMismatchErr {
            value_ptr_or_throw(source, "CastSSA.as_ptoi()::source");
            this.nocheck(PTR_TO_INT,
                source.value_type.type_ctx.get_intptr_type(), source);
        }

        class construct { _istype[TID.CAST_SSA] = true; }
    }
}
