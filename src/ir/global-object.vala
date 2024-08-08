public abstract class Musys.IR.GlobalObject: Constant {
    public enum Visibility {
        INTERNAL, DSO_LOCAL, EXTERNAL,
        RESERVED_COUNT;
        public unowned string get_display_name() {
            if (this >= RESERVED_COUNT)
                return "<undefined>";
            return _gobj_visibl_name_map[this];
        }
    }

    public PointerType ptr_type {
        get { return static_cast<PointerType>(_value_type); }
    }
    public Type content_type { get { return ptr_type.target; } }
    public string name{get;set;}

    public abstract bool is_extern {get;}
    [CCode(notify=false)]
    public abstract bool is_mutable{get;set;}
    public abstract bool enable_impl ();
    public abstract bool disable_impl();

    protected bool _is_internal = false;

    [CCode(notify=false)]
    public    bool  is_internal {
        get { return _is_internal;  }
        set { _is_internal = value; }
    }

    public Visibility visibility {
        get {
            if (is_extern) return EXTERNAL;
            return is_internal? Visibility.INTERNAL: Visibility.DSO_LOCAL;
        }
    }

    public override bool is_zero { get { return false; } }

    protected GlobalObject.C1(Value.TID tid, PointerType type, string name, bool is_internal) {
        base.C1 (tid, type);
        this._is_internal = is_internal;
        this._name = name;
    }
    class construct {
        _istype[TID.GLOBAL_OBJECT] = true;
        _shares_ref               = false;
    }
}

namespace Musys.IR {
    private unowned string _gobj_visibl_name_map[GlobalObject.Visibility.RESERVED_COUNT] = {
        "internal", "dso_local", "external"
    };
}