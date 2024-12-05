musys_ir_src = files([
    'base/exception.vala',
    'base/stdc.vala',
    'base/algorithm.vala',
    'base/apint.vala',
    'base/base.vala',
    'base/stream.vala',
    'base/gee-array-slice.vala',
    'type/type.vala',
    'type/primitive-type.vala',
    'type/aggregate-type.vala',
    'type/struct-type.vala',
    'type/vector-type.vala',
    'type/ref-type.vala',
    'type/function-type.vala',
    'type/platform.vala',
    'type/type-context.vala',
    'ir/use-def.vala',
    'ir/ipointer-storage.vala',
    'ir/value-type-check.vala',
    'ir/constant.vala',
    'ir/const-data.vala',
    'ir/const-undefined.vala',
    'ir/const-expr.vala',
    'ir/const-aggregate.vala',
    'ir/const-array.vala',
    'ir/const-struct.vala',
    'ir/const-index.vala',
    'ir/const-ptr-null.vala',
    'ir/global-object.vala',
    'ir/global-variable.vala',
    'ir/global-alias.vala',
    'ir/function.vala',
    'ir/basic-block.vala',
    'ir/basic-block-terminator.vala',
    'ir/instruction-list.vala',
    'ir/instruction-alloca.vala',
    'ir/instruction-unary.vala',
    'ir/instruction-phi.vala',
    'ir/instruction.vala',
    'ir/instruction-branch.vala',
    'ir/instruction-jump.vala',
    'ir/instruction-switch.vala',
    'ir/instruction-unreachable.vala',
    'ir/instruction-binary.vala',
    'ir/instruction-cast.vala',
    'ir/instruction-load.vala',
    'ir/instruction-store.vala',
    'ir/instruction-return.vala',
    'ir/instruction-binary-select.vala',
    'ir/instruction-index-base.vala',
    'ir/instruction-index-insert.vala',
    'ir/instruction-index-extract.vala',
    'ir/instruction-index-ptr.vala',
    'ir/instruction-jump-base.vala',
    'ir/instruction-compare.vala',
    'ir/instruction-call-base.vala',
    'ir/instruction-call.vala',
    'ir/ivalue-visitor.vala',
    'ir/module.vala',
    'ir-util/value.vala',
    'ir-util/value-type-index.vala',
    'ir-util/basicblock.vala',
    'ir-util/module.vala',
    'ir-util/writer.vala',
    'ir-util/dataflow-printer.vala',
    'ir-util/clone-function.vala',
    'optimize/optimize.vala',
    'optimize/pass.vala',
    'optimize/control-flow/dfs-tree.vala',
    '../csource/musys-backtrace.c',
])

musys_ir_deps = [
    dependency('gee-0.8')
]

add_project_arguments('--enable-mem-profiler', language: 'vala')
add_project_arguments('--enable-gobject-tracing', language: 'vala')

musys_ir_lib = shared_library(
    'musys-ir',
    sources: musys_ir_src,
    dependencies: musys_ir_deps,
    include_directories: musys_include,
    vala_gir: 'musys-ir-0.0.1.gir',
    install: true,
    install_dir: [true, true, true, true]
)

message(musys_ir_lib.name())

musys_pkg_config = import('pkgconfig')
musys_pkg_config.generate(
    libraries: musys_ir_lib,
    subdirs: [musys_include_str, 'src'],
    version: '0.0.1',
    name:     'libmusys-ir',
    filebase: 'musys-ir',
    description: 'LLVM-like compiler framework'
)
