desktop_file_in_config = configuration_data()
desktop_file_in_config.set('app_id', app_id)
desktop_file_in = configure_file(
          input: 'xyz.zateros.Binned.desktop.in',
         output: '@0@.desktop.in'.format(app_id),
  configuration: desktop_file_in_config,
)

desktop_file = i18n.merge_file(
        input: desktop_file_in,
       output: '@0@.desktop'.format(app_id),
         type: 'desktop',
       po_dir: '../po',
      install: true,
  install_dir: get_option('datadir') / 'applications'
)

desktop_utils = find_program('desktop-file-validate', required: false)
if desktop_utils.found()
  test('Validate desktop file', desktop_utils, args: [desktop_file])
endif

appconf = configuration_data()
appconf.set('app_id', app_id)
appstream_file_in = configure_file(
          input: 'xyz.zateros.Binned.metainfo.xml.in',
         output: '@0@.metainfo.xml.in'.format(app_id),
  configuration: appconf,
)

appstream_file = i18n.merge_file(
        input: appstream_file_in,
       output: '@0@.metainfo.xml'.format(app_id),
       po_dir: '../po',
      install: true,
  install_dir: get_option('datadir') / 'metainfo'
)

appstreamcli = find_program('appstreamcli', required: false, disabler: true)
test('Validate appstream file', appstreamcli,
     args: ['validate', '--no-net', '--explain', appstream_file])


schema_conf = configuration_data()
schema_conf.set('app_id', app_id)
schema_conf.set('prefix', prefix)
install_data(
  configure_file(
    input: 'xyz.zateros.Binned.gschema.xml.in',
    output: '@0@.gschema.xml'.format(app_id),
    configuration: schema_conf
  ),
  install_dir: get_option('datadir') / 'glib-2.0' / 'schemas'
)

compile_schemas = find_program('glib-compile-schemas', required: true)
test('Validate schema file',
     compile_schemas,
     args: ['--strict', '--dry-run', meson.current_source_dir()])


service_conf = configuration_data()
service_conf.set('bindir', get_option('prefix') / get_option('bindir'))
service_conf.set('app_id',app_id)
configure_file(
  input: 'xyz.zateros.Binned.service.in',
  output: '@0@.service'.format(app_id),
  configuration: service_conf,
  install_dir: get_option('datadir') / 'dbus-1' / 'services'
)

subdir('icons')
