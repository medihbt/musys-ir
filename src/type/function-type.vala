namespace Musys {
    /**
     * === 函数类型 ===
     *
     * 修饰能被调用的值. 一般不直接出现, 而是作为函数指针的目标.
     *
     * ''类型名称'': `<return type>([arg0[, arg*...]])`
     *
     * - 返回值类型: 可以被实例化的类型或者 `void`. 当返回 `void` 时表示不携带任何返回值.
     * - 参数类型: 长度大于或等于 0 的类型数组. ''要求每个类型都能实例化''. 鉴于 C-ABI
     *   的那种变长参数是既不安全也不跨平台的坏文明, 因此在 Musys-IR 中不论函数类型还是
     *   函数调用语句都''不支持变长参数''.
     */
    public sealed class FunctionType: Type {
        protected size_t _hash_cache;
        public override size_t hash()
        {
            if (_hash_cache != 0)
                return _hash_cache;
            size_t ret = _TID_HASH[TID.FUNCTION_TYPE];
            ret = hash_combine2(ret, _return_type.hash());
            foreach (Type t in params)
                ret = hash_combine2(ret, t.hash());
            _hash_cache = ret;
            return ret;
        }
        protected override bool _relatively_equals(Type rhs)
        {
            if (rhs.tid != FUNCTION_TYPE)
                return false;
            var frhs = static_cast<FunctionType>(rhs);
            if (frhs._params.length != _params.length)
                return false;
            if (!_return_type.equals(frhs._return_type))
                return false;
            for (uint i = 0; i < _params.length; i++) {
                if (!_params[i].equals(frhs._params[i]))
                    return false;
            }
            return true;
        }
        public override size_t instance_size  { get { return 0; } }
        public override size_t instance_align { get { return 0; } }

        /** name = ret_ty(arg0, arg1, arg2, ...) */
        private void _generate_name()
        {
            var builder = new StringBuilder(@"$return_type(");
            uint cnt = 0;
            foreach (Type ty in _params) {
                if (cnt != 0)
                    builder.append(", ");
                builder.append(ty.name);
                cnt++;
            }
            builder.append_c(')');
            _name_len = builder.len;
            _name = builder.free_and_steal();
        }

        protected string _name = null;
        protected size_t _name_len = 0;
        public override string name {
            get {
                if (_name == null)
                    _generate_name();
                return _name;
            }
        }
        public size_t name_len {
            get {
                if (_name == null)
                    _generate_name();
                return _name_len;
            }
        }

        public Type[]   @params{ get; }
        public Type return_type{ get; }

        public FunctionType(Type return_type, Type []params)
        {
            base.C1(TID.FUNCTION_TYPE, return_type.type_ctx);
            _hash_cache = 0;
            this._return_type = return_type;
            this._params      = params;
        }
        public FunctionType.move(Type return_type, owned Type []params)
        {
            base.C1(TID.FUNCTION_TYPE, return_type.type_ctx);
            _hash_cache = 0;
            this._return_type = return_type;
            this._params = (owned)params;
        }
        class construct {
            _istype[TID.FUNCTION_TYPE] = true;
            _is_instantaneous         = false;
        }
    }
}