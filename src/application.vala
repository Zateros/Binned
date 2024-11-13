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

        public Application() {
            Object(
                   application_id : "xyz.zateros.Binned",
                   flags: ApplicationFlags.NON_UNIQUE
            );

            Intl.bindtextdomain (Config.GETTEXT_PACKAGE, Config.LOCALEDIR);
            Intl.bind_textdomain_codeset (Config.GETTEXT_PACKAGE, "UTF-8");
            Intl.textdomain (Config.GETTEXT_PACKAGE);

            settings = new Settings("xyz.zateros.Binned");

            submitter = new Submitter();
            settings.bind("server-address", submitter, "server", DEFAULT);
            settings.bind("auth-token", submitter, "auth", DEFAULT);
            submitter.start.connect(on_start);
            submitter.end.connect(on_end);

            url_match = new Regex("\\b(?:https?://)?(?:www\\.)?([a-zA-Z0-9.-]+\\.[a-zA-Z]{2,})(/[^\\s]*)?\\b");
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
            app = new Application ();
            return app.run (args);
        }

        public override void activate() {
            base.activate();
            win = new Window(this);
            win.on_drop.connect(on_drop);
            win.on_submit.connect(on_submit);
            win.on_clear.connect(on_clear);
            win.on_etime_changed.connect(on_etime);
            win.on_eunit_changed.connect(on_eunit);
            win.present();
            time_unit = win.get_expiration_unit();
        }

        private void on_about_action() {
            string[] developers = { "Zateros" };
            var about = new Adw.AboutDialog() {
                application_name = "Binned",
                application_icon = "xyz.zateros.Binned",
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
                string content_type;

                try {
                    content_type = file.query_info("standard::content-type", GLib.FileQueryInfoFlags.NONE).get_content_type();
                } catch (GLib.Error e) {
                    win.show_toast(@"Something wrong happened during file info query: $(e.message)");
                    return false;
                }

                if (!content_type.contains("text") && !content_type.contains("image")) {
                    win.show_toast(@"“$content_type“ file type is not allowed.");
                    return false;
                }

                file_path = file.get_path();
                dropped = DroppedType.File;
                win.set_filename(file.get_basename());

                if (content_type.contains("image")) { win.set_image(file_path); } else { win.set_icon("rich-text-symbolic"); }
            } else if (value_type == typeof (string)) {
                text = (string) value;
                dropped = DroppedType.Text;
                string display = "";

                if (text.length > 35) { display = text.slice(0, 35) + "..."; } else { display = text; }

                win.set_filename(display);
                if(url_match.match(text)) win.set_icon("globe-alt2-symbolic"); else win.set_icon("document-text-symbolic");
            } else {
                win.show_toast("Unknown object");
                return false;
            }
            bool auto_submit = settings.get_boolean("auto-submit");
            if(!auto_submit) {
                win.show_toast("Opened");
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

        private async void on_submit(bool oneshot) {
            if(!/^\d+$/.match(time)) {
                win.show_toast(@"Invalid time: $time");
                return;
            }
            if (!Thread.supported()) {
                win.show_toast(@"Thread support not detected, cannot continue!");
                return;
            }
            string response = "";
            Gdk.Clipboard clipboard = Gdk.Display.get_default().get_clipboard();

            if(dropped == DroppedType.File) {
                response = yield submitter.send_file_async(file_path,
                    File.new_for_path(file_path)
                                .query_info("standard::content-type", GLib.FileQueryInfoFlags.NONE)
                                .get_content_type(),
                    time,
                    time_unit,
                    oneshot);
            }else {
                if(url_match.match(text)) {
                    response = yield submitter.send_url_async(text, time, time_unit, oneshot);
                }else {
                    response = yield submitter.send_text_async(text, time, time_unit, oneshot);
                }
            }

            if(url_match.match(response)) {
                clipboard.set_text(response);
                win.show_toast(@"Success! Copied url to clipboard");
                win.clear_dropped();
            }
            else { win.show_toast(@"Error while submitting: $response"); }
        }

        private void on_clear() {
            dropped = null;
            text = null;
            file_path = null;
        }

        private void on_start() { win.show_submit_spinner(); }
        private void on_end() { win.show_submit_button(); }

        private void on_etime(string value) { time = value; }
        private void on_eunit(string value) { time_unit = value; }
    }
}
