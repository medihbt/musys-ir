project('musys-ir', ['c', 'vala'], version: '0.0.1')

musys_ir_version= '0.0.1'
musys_include_str='include'
message('[MusysIR] Include directory: '+ musys_include_str)

musys_include= include_directories([
    musys_include_str,
    'src'
])
add_project_arguments('--hide-internal', language: 'vala')

subdir('src')

musys_ir_dep = declare_dependency (
    include_directories: musys_include,
    link_with: musys_ir_lib,
    version:   musys_ir_version
)
