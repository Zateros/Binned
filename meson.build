project('xyz.zateros.Binned', ['c', 'vala'],
          version: '0.1.0',
    meson_version: '>= 1.0.0',
  default_options: [ 'warning_level=2', 'werror=false', ],
)

i18n = import('i18n')
gnome = import('gnome')
valac = meson.get_compiler('vala')

if get_option('devel')
  app_id='xyz.zateros.Binned.Devel'
  prefix='/xyz/zateros/Binned/Devel'
else
  app_id='xyz.zateros.Binned'
  prefix='/xyz/zateros/Binned'
endif

srcdir = meson.project_source_root() / 'src'

config_h = configuration_data()
config_h.set_quoted('APP_ID', app_id)
config_h.set_quoted('PREFIX', prefix)
config_h.set_quoted('PACKAGE_VERSION', meson.project_version ())
config_h.set_quoted('GETTEXT_PACKAGE', meson.project_name())
config_h.set_quoted('LOCALEDIR', get_option('prefix') / get_option('localedir'))
configure_file(output: 'config.h', configuration: config_h)

config_dep = valac.find_library ('config', dirs: srcdir)
config_inc = include_directories('.')

add_project_arguments('-DGETTEXT_PACKAGE="' + meson.project_name () + '"', language: 'c')


subdir('data')
subdir('src')
subdir('po')

gnome.post_install(
     glib_compile_schemas: true,
    gtk_update_icon_cache: true,
  update_desktop_database: true,
)
