project('musys', ['c', 'vala'], version: '0.0.1')

musys_include_str='./include'
message('[Musys] Include directory: '+ musys_include_str)
musys_include=include_directories([
    musys_include_str,
    'src'
])

subdir('src')

musys_dep = declare_dependency(
    include_directories: musys_include,
    link_with: musys_lib
)
