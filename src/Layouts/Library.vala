/*
* Copyright (c) 2011-2018 Alecaddd (http://alecaddd.com)
*
* This program is free software; you can redistribute it and/or
* modify it under the terms of the GNU General Public
* License as published by the Free Software Foundation; either
* version 2 of the License, or (at your option) any later version.
*
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public
* License along with this program; if not, write to the
* Free Software Foundation, Inc., 51 Franklin Street, Fifth Floor,
* Boston, MA 02110-1301 USA
*
* Authored by: Alessandro "Alecaddd" Castellani <castellani.ale@gmail.com>
*/

public class Sequeler.Layouts.Library : Gtk.Grid {
    public weak Sequeler.Window window { get; construct; }

    public Gtk.FlowBox item_box;
    public Gtk.ScrolledWindow scroll;
    public Gtk.Button delete_all;

    public signal void reload_ui ();
    public signal void edit_dialog (Gee.HashMap data);
    public signal void connect_to (Gee.HashMap data, Gtk.Spinner spinner, Gtk.MenuItem button);

    public Library (Sequeler.Window main_window) {
        Object(
            orientation: Gtk.Orientation.VERTICAL,
            window: main_window,
            width_request: 240,
            column_homogeneous: true
        );
    }

    construct {
        var titlebar = new Sequeler.Partials.TitleBar (_("SAVED CONNECTIONS"));

        var toolbar = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        toolbar.get_style_context ().add_class ("library-toolbar");

        var delete_image = new Gtk.Image.from_icon_name ("user-trash-symbolic", Gtk.IconSize.BUTTON);
        delete_all = new Gtk.Button.with_label (_("Delete All"));
        delete_all.get_style_context ().add_class (Gtk.STYLE_CLASS_FLAT);
        delete_all.always_show_image = true;
        delete_all.image = delete_image;
        delete_all.clicked.connect (() => {
            confirm_delete_all ();
        });
        delete_all.can_focus = false;
        delete_all.margin = 6;
        delete_all.sensitive = false;

        toolbar.pack_start (delete_all, false, false, 0);

        scroll = new Gtk.ScrolledWindow (null, null);
        scroll.hscrollbar_policy = Gtk.PolicyType.AUTOMATIC;
        scroll.vscrollbar_policy = Gtk.PolicyType.AUTOMATIC;

        item_box = new Gtk.FlowBox ();
        item_box.activate_on_single_click = false;
        item_box.valign = Gtk.Align.START;
        item_box.min_children_per_line = 1;
        item_box.max_children_per_line = 1;
        item_box.margin = 6;
        item_box.expand = false;

        scroll.add (item_box);

        foreach (var conn in settings.saved_connections) {
            add_item (Sequeler.Services.Settings.arraify_data (conn));
        }

        if (settings.saved_connections.length > 0) {
            delete_all.sensitive = true;
        }

        item_box.child_activated.connect ((child) => {
            var item = child as Sequeler.Partials.LibraryItem;
            item.spinner.start ();
            item.connect_button.sensitive = false;
            connect_to (item.data, item.spinner, item.connect_button);
        });

        attach (titlebar, 0, 0, 1, 1);
        scroll.expand = true;
        attach (scroll, 0, 1, 1, 2);
        attach (toolbar, 0, 3, 1, 1);
    }

    public void add_item (Gee.HashMap<string, string> data) {
        var item = new Sequeler.Partials.LibraryItem (data);
        item_box.add (item);

        item.confirm_delete.connect ((item, data) => {
            confirm_delete (item, data);
        });

        item.edit_dialog.connect ((data) => {
            edit_dialog (data);
        });

        item.connect_to.connect ((data, spinner, connect_button) => {
            spinner.start ();
            connect_button.sensitive = false;
            connect_to (data, spinner, connect_button);
        });
    }

    public void confirm_delete (Gtk.FlowBoxChild item, Gee.HashMap<string, string> data) {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Are you sure you want to proceed?"), _("By deleting this connection you won't be able to recover this data."), "dialog-warning", Gtk.ButtonsType.CANCEL);
        message_dialog.transient_for = window;
        
        var suggested_button = new Gtk.Button.with_label (_("Yes, Delete!"));
        suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        message_dialog.add_action_widget (suggested_button, Gtk.ResponseType.ACCEPT);

        message_dialog.show_all ();
        if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
            settings.delete_connection (data);
            item_box.remove (item);
            reload_library ();
        }
        
        message_dialog.destroy ();
    }

    public void confirm_delete_all () {
        var message_dialog = new Granite.MessageDialog.with_image_from_icon_name (_("Are you sure you want to proceed?"), _("All the data will be deleted and you won't be able to recover it."), "dialog-warning", Gtk.ButtonsType.CANCEL);
        message_dialog.transient_for = window;
        
        var suggested_button = new Gtk.Button.with_label (_("Yes, Delete All!"));
        suggested_button.get_style_context ().add_class (Gtk.STYLE_CLASS_DESTRUCTIVE_ACTION);
        message_dialog.add_action_widget (suggested_button, Gtk.ResponseType.ACCEPT);

        message_dialog.show_all ();
        if (message_dialog.run () == Gtk.ResponseType.ACCEPT) {
            settings.clear_connections ();
            item_box.forall ((item) => item_box.remove (item));
            reload_library ();
        }
        
        message_dialog.destroy ();
    }

    public void reload_library () {
        item_box.show_all ();
        reload_ui ();
    }

    public void check_add_item (Gee.HashMap<string, string> data) {
        foreach (var conn in settings.saved_connections) {
            var check = Sequeler.Services.Settings.arraify_data (conn);
            if (check["id"] == data["id"]) {
                settings.edit_connection (data, conn);
                item_box.forall ((item) => item_box.remove (item));
                foreach (var new_conn in settings.saved_connections) {
                    add_item (Sequeler.Services.Settings.arraify_data (new_conn));
                }
                return;
            }
        }
        settings.add_connection (data);

        add_item (data);

        if (settings.saved_connections.length > 0) {
            delete_all.sensitive = true;
        }
    }
}