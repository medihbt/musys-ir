public errordomain Musys.IR.GlobalAliasErr {
    STEP_OVERFLOW;
}

/**
 * 全局符号别名. 该值接受一个操作数 "aliasee", 相当于给 aliasee 赋予一个新的名称.
 */
public class Musys.IR.GlobalAlias: GlobalObject, IPointerStorage {
    private GlobalObject _aliasee;
    private unowned Use _ualiasee;
    public GlobalObject direct_aliasee {
        get { return _aliasee; }
        set {
            Value refv = _aliasee;
            set_usee_type_match_self(ref refv, value, _ualiasee);
            _aliasee = static_cast<GlobalObject>(refv);
        }
    }
    public GlobalObject get_final_aliasee(uint step_limit = aliasee_search_limit)
                        throws GlobalAliasErr
    {
        GlobalObject target = direct_aliasee;
        for (uint i = 0; i < step_limit; i++) {
            if (!(target is GlobalAlias))
                return target;
            unowned GlobalAlias galias = static_cast<GlobalAlias>(target);
            target = galias.direct_aliasee;
        }
        throw new GlobalAliasErr.STEP_OVERFLOW(
            @"GlobalAlias target searching exceeded step limit $step_limit."
        );
    }
    public GlobalObject make_aliasee_final(uint step_limit = 8) throws GlobalAliasErr {
        this.direct_aliasee = get_final_aliasee(step_limit);
        return _aliasee;
    }

    public override bool enable_impl()  { return false; }
    public override bool disable_impl() { return false; }
    public override bool is_extern { get { return false; } }

    /** "设置全局别名的可变性" 语义不清晰, 不予通过. */
    public override bool is_mutable {
        get {
            try { return get_final_aliasee().is_mutable; }
            catch (Error e) { crash_err(e); }
        }
        set {
            warning("Blocked: try to make global alias {@%s} mutable. "+
                    "Cannot understand what it means to make a global alias mutable or immutable.",
                    name);
        }
    }

    public override void accept(IValueVisitor visitor) {
        visitor.visit_global_alias(this);
    }

    public GlobalAlias.raw(Type content_type, string name, bool is_internal = false) {
        base.C1(GLOBAL_ALIAS, content_type, name, is_internal);
        this._ualiasee = new AliaseeUse().attach_back(this);
    }
    public GlobalAlias.from(GlobalObject aliasee, string name, bool is_internal = false) {
        this.raw(aliasee.content_type, name, is_internal);
        this.direct_aliasee = aliasee;
    }
    class construct { _istype[TID.GLOBAL_ALIAS] = true; }

    public static uint aliasee_search_limit = 8;

    /** 被 GlobalAlias 指向的 Aliasee. */
    private sealed class AliaseeUse: Use {
        public new GlobalAlias user {
            get { return static_cast<GlobalAlias>(_user); }
        }
        public override Value? usee {
            get { return user.direct_aliasee;  }
            set {
                return_if_fail(value is GlobalObject);
                user.direct_aliasee = static_cast<GlobalObject>(value);
            }
        }
    }
}
