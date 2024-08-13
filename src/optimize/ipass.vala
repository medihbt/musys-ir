public interface Musys.IROpt.IPass: IR.IValueVisitor {
    public abstract void run(IR.Module module);
    public abstract IR.Module module{get;set;}
}