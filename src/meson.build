blueprints = custom_target('blueprints',
  input: files(
    'ui/help-overlay.blp',
    'ui/preferences.blp',
    'ui/window.blp',
  ),
  output: '.',
  command: [find_program('blueprint-compiler'), 'batch-compile', '@OUTPUT@', '@CURRENT_SOURCE_DIR@', '@INPUT@'],
)

binned_deps = [
  config_dep,
  dependency('gtk4'),
  dependency('libadwaita-1', version: '>= 1.6'),
  dependency('libsoup-3.0'),
  meson.get_compiler('vala').find_library('gio-2.0'),
]

binned_sources = gnome.compile_resources(
  'binned-resources',
  'binned.gresource.xml',
  dependencies: blueprints,
  c_name: 'binned'
)

binned_sources += files(
  'application.vala',
  'window.vala',
  'preferences.vala',
  'networking/submit.vala',
)

executable('binned', binned_sources,
  vala_args: [
    '--gresourcesdir=src/',
  ],
  dependencies: binned_deps,
  include_directories: config_inc,
  install: true,
)
