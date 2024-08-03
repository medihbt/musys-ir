namespace Musys.IRUtil {
    public class Writer: IR.IValueVisitor {
        private Runtime  *_rt;
        public  IR.Module module;
        public void write_stream(IOutputStream? stream = null)
        {
            Runtime rt = {};
            if (stream == null)
                rt.outs = new FileOutStream(stdout);
            else
                rt.outs = stream;
            _rt = &rt;
            visit_module();
            _rt = null;
        }
        public void write_file(GLib.FileStream file = stdout) {
            write_stream(new FileOutStream(file));
        }
        private void visit_module() {
            foreach (var def in module.global_def)
                def.value.accept(this);
        }

        private void _write_by_ref(IR.Value value)
        {
            if (value.shares_ref)
                value.accept(this);
            _rt->outs.printf("%d", value.id);
        }

        public Writer(IR.Module module) {
            this.module = module;
        }

        public struct Runtime {
            IOutputStream outs;
        }
    }
}