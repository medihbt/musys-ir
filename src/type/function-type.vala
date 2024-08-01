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
            if (!rhs.is_function)
                return false;
            var frhs = (FunctionType)rhs;
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
        public override string name {
            get {
                if (_name != null)
                    return (string)_name;
                unowned string retty_name = _return_type.name;
                size_t         retty_len  = retty_name.length;

                const uint sep_length = 2;
                size_t   total_length = retty_len + 2; // + size of '()'
                foreach (unowned Type ty in _params)
                    total_length += ty.name.length + sep_length;
                total_length -= sep_length;         // ending without ', '

                _name = new char[total_length + 1]; // terminating '\0'

                char *needle = _name;
                Memory.copy(needle, retty_name, retty_len);
                needle += retty_len;
                *needle = '(';
                needle++;

                foreach (unowned Type ty in _params) {
                    unowned string argty_name = ty.name;
                    size_t         argty_len  = argty_name.length;
                    Memory.copy(needle, argty_name, argty_len);
                    needle += argty_len;
                    needle[1] = ','; needle[2] = ' ';
                    needle += 2;
                }
                needle[1] = ')'; needle[2] = '\0';
                return (string)_name;
            }
        }

        public Type []params{get;}
        public Type return_type{get;}
        protected size_t _hash_cache;
        protected char []_name = null;

        public FunctionType(Type return_type, Type []params)
        {
            _hash_cache = 0;
            this._return_type = return_type;
            this._params      = params;
        }
        public FunctionType.move(Type return_type, owned Type []params)
        {
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