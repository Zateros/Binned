/* application.vala
 *
 * Copyright 2024 Zateros
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */
namespace Binned {
    public errordomain BinnedError {
        BLACKLISTED_MIME,
        FILE_OPEN_ERROR,
    }

    public Application app;
    public Window win;

    public class Application : Adw.Application {

        public enum DroppedType {
            Text,
            File
        }

        private Settings settings;
        private DroppedType? dropped;
        private Submitter submitter;
        private Regex url_match;
        
        private string? file_path;
        private string? text;

        private string? time = "15";
        private string? time_unit;

        private string shortname;

        private string[] mimetypes;

        public Application() {
            Object(
                   application_id : Config.APP_ID,
                   flags: ApplicationFlags.NON_UNIQUE
            );

            // Hardcoded whitelisted mimetypes,
            // because RustyPaste does not expose blocked mimetypes
            mimetypes = new string[] {
                "image/jpeg",
                "image/png",
                "image/gif",
                "image/bmp",
                "image/webp",
                "image/tiff",
                "image/svg+xml",
                "text/plain",
                "text/html",
                "text/css",
                "text/csv",
                "audio/mpeg",
                "audio/ogg",
                "audio/wav",
                "audio/vnd.wave",
                "audio/flac",
                "audio/aac",
                "audio/x-midi",
                "application/json",
                "application/xml",
                "application/msword",
                "application/vnd.openxmlformats-officedocument.wordprocessingml.document",
                "application/vnd.oasis.opendocument.text",
                "application/vnd.ms-excel",
                "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
                "application/zip",
                "application/x-tar",
                "application/x-7z-compressed",
                "application/x-rar-compressed",
                "application/gzip"
            };

            settings = new Settings(Config.APP_ID);

            submitter = new Submitter();
            settings.bind("server-address", submitter, "server", DEFAULT);
            settings.bind("auth-token", submitter, "auth", DEFAULT);
            submitter.start.connect(on_submit_start);
            submitter.end.connect(on_submit_end);

            try {
                url_match = new Regex("\\b(?:https?://)?(?:www\\.)?([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})(/[^\\s]*)?\\b");
            }catch (RegexError e) {
                print(e.message);
            }
        }

        construct {
            ActionEntry[] action_entries = {
                { "about", this.on_about_action },
                { "preferences", this.on_preferences },
                { "quit", this.quit }
            };
            this.add_action_entries(action_entries, this);
            this.set_accels_for_action("app.quit", { "<primary>q" });
        }

        public static int main (string[] args) {
            Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
            Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (Config.GETTEXT_PACKAGE);
            app = new Application ();
            return app.run (args);
        }

        public override void activate() {
            base.activate();
            win = new Window(this);
            win.on_drop.connect(on_drop);
            win.on_submit.connect(on_submit);
            win.on_file_open.connect(on_file_connect);
            win.on_clear.connect(() => {
                dropped = null;
                text = null;
                file_path = null;
                win.file_opened = false;
            });
            win.on_etime_changed.connect((value) => { time = value; });
            win.on_eunit_changed.connect((value) => { time_unit = value; });
            win.on_shortname_changed.connect((value) => {shortname = value;});
            win.present();
            time_unit = win.get_expiration_unit();
        }

        private void on_about_action() {
            string[] developers = { "Zateros" };
            var about = new Adw.AboutDialog() {
                application_name = "Binned",
                application_icon = Config.APP_ID,
                developer_name = "Zateros",
                translator_credits = _("translator-credits"),
                version = "0.1.0",
                developers = developers,
                copyright = "© 2024 Zateros",
            };

            about.present(this.active_window);
        }

        private void on_preferences() {
            Adw.PreferencesDialog prefs = new Preferences();
            prefs.present(win);
        }

        private bool on_drop(Gtk.DropTarget self, Value value) {
            var value_type = value.type();

            if (value_type == typeof (Gdk.FileList)) {
                GLib.File file = ((Gdk.FileList) value).get_files().nth_data(0);

                try {
                    process_file(file);
                    win.file_opened = true;
                    return true;
                } catch {
                    return false;
                }
            } else if (value_type == typeof (string)) {
                text = (string) value;
                dropped = DroppedType.Text;
                string display = "";

                if (text.length > 35) { display = text.slice(0, 35) + "..."; } else { display = text; }

                win.set_filename(display);
                if(url_match.match(text)) win.set_icon("globe-alt2-symbolic"); else win.set_icon("document-text-symbolic");
                win.file_opened = true;
            } else {
                win.show_toast(_("Unknown object"));
                return false;
            }

            bool auto_submit = settings.get_boolean("auto-submit");
            if(!auto_submit) {
                win.show_toast(_("Opened"));
                return true;
            }else {
                bool oneshot = settings.get_boolean("auto-submit-oneshot");
                time = settings.get_string("auto-submit-expiry");
                string[] units = {"Nanoseconds", "Microseconds", "Miliseconds", "Seconds", "Minutes", "Hours", "Days", "Weeks", "Months", "Years"};
                int unit_ind = settings.get_int("auto-submit-unit");

                time_unit = units[unit_ind];

                on_submit(oneshot);
                return true;
            }
        }

        private void process_file(File file) throws BinnedError {
            string content_type;

            try {
                content_type = file.query_info("standard::content-type", GLib.FileQueryInfoFlags.NONE).get_content_type();
            } catch (GLib.Error e) {
                win.show_toast(_(@"Something wrong happened during file info query: $(e.message)"));
                throw new BinnedError.FILE_OPEN_ERROR("");
            }

            if (!(content_type in mimetypes)) {
                win.show_toast(_(@"“$content_type“ file type is not allowed."));
                throw new BinnedError.BLACKLISTED_MIME("");
            }

            file_path = file.get_path();
            dropped = DroppedType.File;
            win.set_filename(file.get_basename());

            if (content_type.contains("image")) { win.set_image(file_path); } 
            else if (content_type.contains("zip") || content_type.contains("compressed") || content_type.contains("tar")) { win.set_icon("package-x-generic-symbolic"); }
            else { win.set_icon("rich-text-symbolic"); }
        }

        private bool on_file_connect(File file) {
            try {
                process_file(file);
                return true;
            } catch (BinnedError b) {
                return false;
            }
        }

        private async void on_submit(bool oneshot) {
            if(!/^\d+$/.match(time)) {
                win.show_toast(_(@"Invalid time: $time"));
                return;
            }
            if (!Thread.supported()) {
                win.show_toast(_("Thread support not detected, cannot continue!"));
                return;
            }
            string response = "";
            Gdk.Clipboard clipboard = Gdk.Display.get_default().get_clipboard();

            if(dropped == DroppedType.File) {
                string mimetype;
                try {
                    mimetype = File.new_for_path(file_path)
                                .query_info("standard::content-type", GLib.FileQueryInfoFlags.NONE)
                                .get_content_type();
                }catch (Error e) {
                    win.show_toast(_(@"Error getting file mimetype: $(e.message)"));
                    return;
                }
                response = yield submitter.send_file_async(file_path,
                    mimetype,
                    time,
                    time_unit,
                    shortname,
                    oneshot);
            }else {
                if(url_match.match(text)) {
                    response = yield submitter.send_url_async(text, time, time_unit, shortname, oneshot);
                }else {
                    response = yield submitter.send_text_async(text, time, time_unit, shortname, oneshot);
                }
            }

            if(url_match.match(response)) {
                clipboard.set_text(response);
                win.show_toast(_("Success! Copied url to clipboard"));
                win.clear_dropped();
            }
            else { win.show_toast(_(@"Error while submitting: $response")); }
        }
    }

    private void on_submit_start() { win.show_submit_spinner(); }
    private void on_submit_end() { win.show_submit_button(); }
}
