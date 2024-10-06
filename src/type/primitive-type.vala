namespace Musys {
    /**
     * 求能装下二进制位数为 `bit` 的整数的存储单元的最小字节数.
     *
     * **Musys 只支持一字节有 8 位的目标机器**. 好在大多数机器一字节有 8 位, 因此应该不会有什么问题.
     */
    internal inline size_t bit_to_byte(size_t bit) {
        return bit / 8 + (size_t)(bit % 8 != 0);
    }
    /**
     * 求一个字节数为 bytes 的存储单元需要的最小对齐字节数是多少.
     *
     * @param bytes 字节数. 例如, `i32` 的字节数是 4.
     *
     * @param word_size 目标机器的字长. 例如, `amd64` 平台的字长是 8.
     */
    internal inline size_t size_get_align(size_t bytes, size_t word_size) {
        if (bytes >= word_size)
            return word_size;
        return fill_to_pwr_of_2(bytes);
    }

    /**
     * 标量类型, 包括整数与浮点在内, 可以参与四则运算、不可再分的类型.
     *
     * 标量类型的大小是按位算的, 其属性 `binary_bits` 就是该类型所占的二进制位数.
     */
    public abstract class PrimitiveType: Type {
        protected uint32 _binary_bits;
        /** 该类型所占的二进制位大小. 例如 i32 占 32 位, double 占 64 位. */
        public    uint32  binary_bits{
            get { return _binary_bits; }
            internal set { _binary_bits = value; }
        }

        /**
         * {@link Musys.Type.instance_size}
         */
        public override size_t instance_size {
            get { return bit_to_byte(_binary_bits); }
        }

        /**
         * {@link Musys.Type.instance_align}
         */
        public override size_t instance_align {
            get { return size_get_align(
                instance_size, type_ctx.machine_word_size
            ); }
        }

        /** 名称缓存. */
        protected string _name = null;

        protected PrimitiveType.C1(TypeContext tctx, TID tid, uint32 binary_bits)
        {
            base.C1(tid, tctx);
            this._binary_bits = binary_bits;
        }
        class construct {
            _istype[TID.PRIMITIVE_TYPE] = true;
        }
    }

    /**
     * 表示一定二进制位数的整数类型. 理论上, 其二进制位可以填写任何正整数. 但受限于 APInt 整数类型的实现,
     * Musys-IR 只支持 1~64 这 64 种二进制位.
     *
     * Musys 整数类型不存储符号信息, 也就是说, `int32_t` 和 `uint32_t` 都会映射到 i32. 在 Musys IR 中,
     * 符号的处理是通过具体的指令进行的. 例如, 在 BinarySSA 双操作数指令中:
     *
     * {{{
     *     %1 = add nsw i32  1, 2 ;处理有符号操作使用 nsw 修饰
     *     %2 = add nuw i32 %1, 3 ;处理无符号操作使用 nuw 修饰
     * }}}
     *
     * 在 TypeContext 中, 调用 `TypeContext.get_int_type(bit)` 方法可以获取二进制位为 bit 的整数.
     */
    public sealed class IntType: PrimitiveType {
        public override string name {
            get {
                if (_name == null)
                    _name = @"i$(_binary_bits)";
                return _name;
            }
        }
        public override size_t hash() {
            return _TID_HASH[TID.INT_TYPE] + _binary_bits * 257;
        }
        protected override bool _relatively_equals(Type rhs) {
            if (rhs.tid != INT_TYPE)
                return false;
            unowned IntType irhs = static_cast<IntType>(rhs);
            return irhs._binary_bits == _binary_bits;
        }

        public IntType(TypeContext tctx, uint32 binary_bits) {
            base.C1(tctx, TID.INT_TYPE, binary_bits);
        }
        class construct { _istype[TID.INT_TYPE] = true; }
    }

    /**
     * 表示包含一定位数指数、一定位数底数的有/无符号二进制浮点类型. 理论上, 其所有二进制位
     * 可以填写任何整数. 但是受限于实现方式, Musys 只支持 IEEE Float32 和 IEEE Float64
     * 两种浮点, ''不支持'' IEEE Float16, Google BFloat16, Float128等等其他浮点类型.
     *
     * 受限于 FloatType 的表达能力, Musys 不支持十进制浮点类型.
     */
    public sealed class FloatType: PrimitiveType {
        public override size_t hash() {
            uint32 uid = ((uint32)_is_signed << 31) |
                         (_index_bits << 16) | (_tail_bits);
            return hash_combine2(_TID_HASH[TID.FLOAT_TYPE], uid);
        }

        public override string name { get { return _name; } }
        protected override bool _relatively_equals(Type rhs)
        {
            if (rhs.tid != FLOAT_TYPE)
                return false;
            var frhs = (FloatType)rhs;
            return frhs._tail_bits == _tail_bits  &&
                   frhs._index_bits== _index_bits &&
                   frhs._is_signed == _is_signed  &&
                   frhs._name      == _name;
        }

        public bool   is_signed {get;}
        public uint16 index_bits{get;}
        public uint16 tail_bits {get;}

        public FloatType.full(TypeContext tctx,  string name,
                         uint16 index_bits, uint16 tail_bits, bool is_signed = true)
        {
            base.C1(tctx, TID.FLOAT_TYPE,
                    (uint)is_signed + index_bits + tail_bits);
            this._name        = name;
            this._index_bits  = index_bits;
            this._tail_bits   = tail_bits;
            this._is_signed   = is_signed;
        }
        public FloatType.ieee_fp32(TypeContext tctx) {
            this.full(tctx, "float", 8, 23, true);
        }
        public FloatType.ieee_fp64(TypeContext tctx) {
            this.full(tctx, "double", 11, 52, true);
        }
        class construct { _istype[TID.FLOAT_TYPE] = true; }
    }
}