/* preferences.vala
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

[GtkTemplate (ui = "/xyz/zateros/Binned/ui/preferences.ui")]
public class Binned.Preferences : Adw.PreferencesDialog {

    private Settings settings;

    [GtkChild]
    private unowned Adw.EntryRow server_address;
    [GtkChild]
    private unowned Adw.EntryRow auth_token;
    [GtkChild]
    private unowned Adw.ExpanderRow auto_submit;
    [GtkChild]
    private unowned Adw.SwitchRow as_oneshot_switch;
    [GtkChild]
    private unowned Adw.EntryRow as_expiration_time;
    [GtkChild]
    private unowned Adw.ComboRow as_expiration_unit;

    construct {
        settings = new Settings (Config.APP_ID);

        settings.bind("server-address", server_address, "text", DEFAULT);
        settings.bind("auth-token", auth_token, "text", DEFAULT);
        settings.bind("auto-submit", auto_submit, "enable-expansion", DEFAULT);
        settings.bind("auto-submit-oneshot", as_oneshot_switch, "active", DEFAULT);
        settings.bind("auto-submit-expiry", as_expiration_time, "text", DEFAULT);
        settings.bind("auto-submit-unit", as_expiration_unit, "selected", DEFAULT);

        server_address.changed.connect (validate_url);
        as_expiration_time.changed.connect(validate_expiration_time);
    }

    private void validate_url() {
        if(!/^https?:\/\/(?:www\.)?(?:[^\/\n]+\.[^\/\n]+)(?:\/(?!.*\.[a-zA-Z]{2,6}(?:[\/\n]|$)).*)?$/.match(server_address.text)) {
            server_address.set_css_classes({"error"});
        }else {
            server_address.set_css_classes({});
        }
    }

    private void validate_expiration_time() {
        if(!/^\d+$/.match(as_expiration_time.text)) {
            as_expiration_time.set_css_classes({"numeric", "error"});
        }else {
            as_expiration_time.set_css_classes({"numeric"});
        }
    }
}
