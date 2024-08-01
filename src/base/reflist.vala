namespace Musys {
    public interface IRefListElem<ElemT>: Object {
        public abstract RefList<ElemT> parent_list{get;}

        public abstract void on_append_preprocess();
        public abstract void on_prepend_preprocess();
    }
    public class RefList<ElemT> {

        public class Node<ElemT> {
            public         Node next;
            public unowned Node prev;
            public IRefListElem<ElemT> ielem;
            public ElemT element {
                get { return (ElemT)ielem; }
                set { ielem = value as IRefListElem<ElemT>; }
            }
        }

        protected Node<ElemT> _node_begin;
        protected Node<ElemT> _node_end;
    }
}