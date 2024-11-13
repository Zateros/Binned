/* window.vala
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

[GtkTemplate (ui = "/xyz/zateros/Binned/ui/window.ui")]
public class Binned.Window : Adw.ApplicationWindow {
    Gtk.DropTarget drop_target;

    [GtkChild]
    private unowned Gtk.Stack main_stack;
    [GtkChild]
    private unowned Gtk.Stack submit_stack;
    [GtkChild]
    private unowned Adw.SwitchRow oneshot_switch;
    [GtkChild]
    private unowned Gtk.Button submit_button;
    [GtkChild]
    private unowned Gtk.Button clear_button;
    [GtkChild]
    private unowned Adw.ToastOverlay toast_overlay;
    [GtkChild]
    private unowned Gtk.Image representation_image;
    [GtkChild]
    private unowned Gtk.Label file_name;
    [GtkChild]
    private unowned Adw.EntryRow expiration_time;
    [GtkChild]
    private unowned Adw.ComboRow expiration_unit;

    public Window (Gtk.Application app) {
        Object (application: app);
    }

    construct {
        drop_target = new Gtk.DropTarget(Type.NONE, Gdk.DragAction.COPY);
        drop_target.set_gtypes(new Type[]{typeof (Gdk.FileList), Type.STRING});
        drop_target.enter.connect(drop_target_enter);
        drop_target.leave.connect(drop_target_leave);
        drop_target.drop.connect(drop_target_drop);
        ((Gtk.Widget) this).add_controller(drop_target);

        submit_button.clicked.connect(submit_button_pressed);

        clear_button.clicked.connect(clear_dropped);

        expiration_time.changed.connect(validate_expiration_time);
        expiration_unit.notify["selected-item"].connect(eunit_changed);
    }

    public signal bool on_drop(Gtk.DropTarget self, Value value);
    public signal void on_submit(bool oneshot);
    public signal void on_clear();
    public signal void on_etime_changed(string value);
    public signal void on_eunit_changed(string value);

    public void set_image(string path) { representation_image.set_from_file(path); }
    public void set_icon(string icon) { representation_image.set_from_icon_name(icon); }
    public void set_filename(string name) { file_name.label = name; }
    public string get_expiration_unit() { return ((Gtk.StringObject)expiration_unit.selected_item).get_string(); }

    public void show_toast(string message) {
        Adw.Toast toast = new Adw.Toast(message);
        toast.set_timeout(1);
        toast_overlay.add_toast(toast);
    }
    
    public void clear_dropped() {
        on_clear();
        main_stack.set_visible_child_full("default_page", Gtk.StackTransitionType.CROSSFADE);
        clear_button.visible = false;
    }

    public void show_submit_spinner() { submit_stack.set_visible_child_full("submit_stack_spinner", Gtk.StackTransitionType.CROSSFADE); }
    public void show_submit_button() { submit_stack.set_visible_child_full("submit_stack_button", Gtk.StackTransitionType.CROSSFADE); }
    
    private void submit_button_pressed() { on_submit(oneshot_switch.active); }

    private Gdk.DragAction drop_target_enter(Gtk.DropTarget self,
        double x,
        double y) {
        main_stack.set_visible_child_full("dragging_page", Gtk.StackTransitionType.CROSSFADE);
        return Gdk.DragAction.COPY;
    }

    private void drop_target_leave(Gtk.DropTarget self) {
        main_stack.set_visible_child_full("default_page", Gtk.StackTransitionType.CROSSFADE);
    }

    private bool drop_target_drop(Gtk.DropTarget self, Value value, double x, double y) {
        if(!on_drop(self, value)) return false;
        clear_button.visible = true;
        main_stack.set_visible_child_full("post_drag_page", Gtk.StackTransitionType.CROSSFADE);
        return true;
    }

    private void eunit_changed() { on_eunit_changed(((Gtk.StringObject)expiration_unit.selected_item).get_string()); }

    private void validate_expiration_time() {
        on_etime_changed(expiration_time.text);
        if(!/^\d+$/.match(expiration_time.text)) {
            expiration_time.set_css_classes({"numeric", "error"});
        }else {
            expiration_time.set_css_classes({"numeric"});
        }
    }
}
