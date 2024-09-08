namespace Musys {
    public sealed class FunctionType: Type {
        public override size_t hash()
        {
            if (_hash_cache != 0)
                return _hash_cache;
            size_t ret = _TID_HASH[TID.FUNCTION_TYPE];
            ret = hash_combine2(ret, _return_type.hash());
            foreach (unowned Type t in params)
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
            if (_is_var_args != frhs._is_var_args)
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
            if (is_var_args)
                builder.append(", ...");
            builder.append_c(')');
            _name_len = builder.len;
            _name = builder.free_and_steal();
        }
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

        /** 用于函数调用类指令. 判断当被调用的函数是自己时, 调用者所表示的函数类型合不合法. */
        public bool fits_function(FunctionType type)
        {
            if (!is_var_args)
                return equals(type);
            if (!return_type.equals(type.return_type))
                return false;
            unowned Type[] lparams = @params, rparams = type.params;
            if (rparams.length < lparams.length)
                return false;
            return array_nequals(lparams, rparams, lparams.length);
        }

        public Type []@params{get;}
        public Type return_type{get;}
        public bool is_var_args{get;}
        protected size_t _hash_cache;
        protected string _name = null;
        protected size_t _name_len = 0;

        public FunctionType(Type return_type, Type []params, bool is_varargs = false)
        {
            _hash_cache = 0;
            this._return_type = return_type;
            this._params      = params;
            this._is_var_args = is_varargs;
        }
        public FunctionType.move(Type return_type, owned Type []params, bool is_varargs = false)
        {
            _hash_cache = 0;
            this._return_type = return_type;
            this._params = (owned)params;
            this._is_var_args = is_varargs;
        }
        class construct {
            _istype[TID.FUNCTION_TYPE] = true;
            _is_instantaneous         = false;
        }
    }
}