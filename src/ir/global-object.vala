/**
 * ''全局对象'': 程序静态数据的抽象, 表示存储全局变量、全局常量和函数的存储单元.
 *
 * 因为是存储单元, 全局对象的类型都是指针类型. 由于 Musys 的指针都是不透明的,
 * 因此 ``GlobalObject`` 实现了 ``IPointerValue`` 接口以传达自己能存放的
 * 数据类型.
 */
public abstract class Musys.IR.GlobalObject: Constant, IPointerStorage {
    /** 全局对象的可见性. */
    public enum Visibility {
        /** 仅内部可见 */
        INTERNAL,
        /** 内外部都可见, 并且对内暴露实现 */
        DSO_LOCAL,
        /** 内外部都可见, 不对内暴露实现 */
        EXTERNAL,
        RESERVED_COUNT;

        public unowned string get_display_name()
        {
            if (this >= RESERVED_COUNT)
                return "<undefined>";
            return _gobj_visibl_name_map[this];
        }
    }

    /** 自己的类型, 实际是个指针. */
    public PointerType ptr_type {
        get { return static_cast<PointerType>(_value_type); }
    }
    /** 内含元素类型. */
    public Type content_type { get; internal set; }

    /** (实现 IPointerStorage 接口) */
    public Type get_ptr_target() { return content_type; }

    /** 自己的名称. GlobalObject 是极少数有字符串名称的 Value 子类之一. */
    public string name{get;set;}

    /** 表示自己的实现是不是外部的. */
    public abstract bool is_extern {get;}
    /** 表示自己所在的内存区域可不可变. */
    [CCode(notify=false)]
    public abstract bool is_mutable{get;set;}

    /** 启用自己的默认实现 -- 也就是把自己从全局声明变成全局定义. */
    public abstract bool enable_impl ();
    /** 禁用自己的默认实现 -- 也就是把自己从全局定义变成全局声明. */
    public abstract bool disable_impl();

    protected bool _is_internal = false;

    /** 表示这个全局对象是不是只有模块内部的对象才可见的. */
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

    /** 全局对象固定表示某个至少可读/可执行的指针, 这个指针一般不会是 null. */
    public override bool is_zero { get { return false; } }

    protected GlobalObject.C1(Value.TID tid, Type content_type, string name, bool is_internal) {
        var tctx = content_type.type_ctx;
        base.C1(tid, tctx.opaque_ptr);
        this.content_type = content_type;
        this._is_internal = is_internal;
        this._name = name;
    }
    class construct {
        _istype[TID.GLOBAL_OBJECT]  = true;
        _istype[TID.IPOINTER_STORAGE] = true;
        _shares_ref               = false;
    }
}

namespace Musys.IR {
    private unowned string _gobj_visibl_name_map[GlobalObject.Visibility.RESERVED_COUNT] = {
        "internal", "dso_local", "external"
    };
}