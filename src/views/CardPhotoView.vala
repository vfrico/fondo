/*
* Copyright (C) 2018  Calo001 <calo_lrc@hotmail.com>
* 
* This program is free software: you can redistribute it and/or modify
* it under the terms of the GNU Affero General Public License as published
* by the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
* 
* This program is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU Affero General Public License for more details.
* 
* You should have received a copy of the GNU Affero General Public License
* along with this program.  If not, see <http://www.gnu.org/licenses/>.
* 
*/

using App.Configs;
using App.Structs;
using App.Connection;
using App.Utils;
using App.Widgets;
using Gtk;

namespace App.Views {

    /**
     * The {@code CardPhotoView} class.
     *
     * @since 1.0.0
     */

    public class CardPhotoView : Gtk.Grid {
        
        public signal void set_as_wallpaper(string opt = "zoom");

        private File                    file_photo;
        private Granite.AsyncImage      image;
        private Button                  btn_view;
        private EventBox                eventbox_photo;
        private LinkButton              label_autor;
        private Wallpaper               wallpaper;
        private AppConnection           connection;
        private ProgressBar             bar;
        private Revealer                revealer;
        private Overlay                 overlay;
        private Photo                   photo;
        private PopupWallpaper          popup_content;
        private Popover                 popup;
        private Gtk.Box                 grid_actions;
        
        // Construct
        public CardPhotoView (Photo photo) {
            this.connection = AppConnection.get_instance();
            this.photo = photo;
            this.orientation = Gtk.Orientation.VERTICAL;
            this.margin_bottom = 10;
            this.margin_top = 10;
            this.margin_start = 10;
            this.margin_end = 10;
            this.halign = Gtk.Align.CENTER;
            this.valign = Gtk.Align.CENTER;

            /******************************************
                    File from url thumb
            ******************************************/
            file_photo = File.new_for_uri (photo.urls_thumb);
            
            /******************************************
                    Create AsyncImage object
            ******************************************/
            
            image = new Granite.AsyncImage(true, true);
            var w = 
            var h =
            image.set_from_file_async.begin(file_photo, 280, 180, false); // Width, Heigth
            image.has_tooltip = true;
            image.get_style_context ().add_class ("photo");            
            var txt_tooltip = photo.location == null ? 
                _("🌎  An amazing place in the world") : 
                "🌎  " + photo.location;
            image.set_tooltip_text (txt_tooltip);

            /******************************************
                    Create Popover
            ******************************************/
            popup = new Popover(this);
            popup.position = Gtk.PositionType.BOTTOM;
            popup.modal = true;
            popup_content = new PopupWallpaper(photo.width, photo.height);
            popup.add(popup_content);

            // Detect signal
            popup_content.wallpaper_option.connect((opt) => {
                this.set_sensitive (false);
                popup.set_visible (false);
                revealer.set_reveal_child (true);
                string? url_photo = connection.get_url_photo(photo.links_download_location);
                setup_wallpaper(url_photo, opt);
                
            });

            /******************************************
                    Create EventBox for Image
            ******************************************/
            eventbox_photo = new Gtk.EventBox();
            eventbox_photo.button_release_event.connect ( (event) => {
                if (event.type == Gdk.EventType.BUTTON_RELEASE && event.button == 3) {
                    popup.set_visible (true);
                } else {
                    this.set_sensitive (false);  
                    revealer.set_reveal_child (true);
                    string? url_photo = connection.get_url_photo(photo.links_download_location);
                    setup_wallpaper(url_photo);
                }
                return true;
            } );

            eventbox_photo.add(image);

            /******************************************
                        Fullscreen button
            ******************************************/
            btn_view = new Gtk.Button.from_icon_name ("window-maximize-symbolic");
            btn_view.get_style_context ().add_class ("button-green");
            btn_view.get_style_context ().remove_class ("button");
            btn_view.get_style_context ().add_class ("transition");
            btn_view.can_focus = false;
            btn_view.margin = 8;
            btn_view.halign = Gtk.Align.END;
            btn_view.valign = Gtk.Align.START;

            btn_view.clicked.connect (() => {
                this.set_sensitive (false);
                var prev_win = new PreviewWindow(photo);
                prev_win.closed_preview.connect (() => {
                    this.set_sensitive (true);            
                });
                prev_win.show_all ();
                // MUST TO BE REIMPLEMENTED
                prev_win.load_content();
		    });

            /********************************************************
                    Create Overlay (contain img, btnFullScreen)
            ********************************************************/
            overlay = new Gtk.Overlay();
            overlay.add (eventbox_photo);
            overlay.add_overlay (btn_view);            
            overlay.width_request = 280;
            overlay.height_request = 180;

            /******************************************
                        Create Label Autor
            ******************************************/
            var link = @"https://unsplash.com/@$(photo.username)?utm_source=$(Constants.PROGRAME_NAME)&utm_medium=referral";
            label_autor = new Gtk.LinkButton.with_label(link, _("By ") + photo.name);
            label_autor.get_style_context ().remove_class ("button");
            label_autor.get_style_context ().remove_class ("link");
            label_autor.get_style_context ().add_class ("transition");
            label_autor.get_style_context ().add_class ("autor");
            label_autor.get_style_context ().remove_class ("flat");
            label_autor.margin_top = 8;
            label_autor.halign = Gtk.Align.CENTER;
            label_autor.has_tooltip = false;
            label_autor.can_focus = false;

            /******************************************
                        Progressbar card
            ******************************************/
            bar = new Gtk.ProgressBar ();
            bar.margin_top = 8;

            /******************************************
                        Revealer for progress
            ******************************************/
            revealer = new Gtk.Revealer ();
            revealer.add (bar);

            /******************************************
                        Add all views
            ******************************************/
            this.add(overlay);            
            this.add(revealer);
            this.add(label_autor);

            show_all_controls();
        }

        private void scale (int w_h_photo, int w_h_card) {
            double card_scale = (double) w_h_card / (double) w_h_photo;
            w_photo = (int)(w_photo * card_scale);
            h_photo = (int)(h_photo* card_scale);
        }

        private void setup_wallpaper (string url, string opt = "zoom") {
            wallpaper = new Wallpaper (url, photo.id, photo.username, bar);
            wallpaper.finish_download.connect (() => {
                this.set_sensitive (true);    
                print("Finish download");        
            });
            wallpaper.update_wallpaper (opt);
        }

        private void show_all_controls() {
            overlay.show();
            eventbox_photo.show();
            btn_view.show();
            label_autor.show();
            image.show();
            revealer.show();
            bar.show();
            grid_actions.show();
        }
    }

}
