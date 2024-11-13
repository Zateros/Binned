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

resource_conf = configuration_data()
resource_conf.set('prefix', prefix)
resource = configure_file(
    input: 'binned.gresource.xml.in',
    output: 'binned.gresource.xml',
    configuration: resource_conf
  )

binned_sources = gnome.compile_resources(
  'binned-resources',
  resource,
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
