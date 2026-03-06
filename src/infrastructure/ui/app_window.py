from domain.UseCase.get_home_content_uc import GetHomeContentUC
import gi
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.repository.api_cache_repository import ApiCacheRepository
from infrastructure.repository.appstream_repository import AppstreamRepository
from infrastructure.ui.appstream_ui import AppstreamPage

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw



class MainWindow(Adw.ApplicationWindow):


    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

       
        self.set_title("Nix Samba")
        self.set_default_size(800, 600)

        self._toast_overlay = Adw.ToastOverlay()
        self.set_content(self._toast_overlay)

        # Create navigation view for in-window navigation
        self.navigation_view = Adw.NavigationView()
        self._toast_overlay.set_child(self.navigation_view)

        # Create and push the home page
        home_page = self._create_home_page()
        self.navigation_view.push(home_page)

        # Handle close request to prompt for unsaved changes
        self.connect('close-request', self._on_close_request)

        

     
    def _create_home_page(self):
        page = Adw.NavigationPage.new(self._create_home_content(), _('Nix Samba'))
        return page

    def _create_home_content(self):
        # Create toolbar view with header bar
        toolbar_view = Adw.ToolbarView()
        header_bar = Adw.HeaderBar()

        toolbar_view.add_top_bar(header_bar)

        # Create preferences page
        pref_page_home = Adw.PreferencesPage()
        pref_page_home.set_title(_('Home'))

        # First group
        pref_group_trending_apps = Adw.PreferencesGroup()
        pref_group_trending_apps.set_title(_('Trending apps'))
        
        appstream_repository = AppstreamRepository()
        get_home_content_uc = GetHomeContentUC(ApiCacheRepository(), appstream_repository, FlathubApi())
        trending_application_list = get_home_content_uc.get_trending_appstream_list()

        flow_box = Gtk.FlowBox()
        flow_box.set_selection_mode(Gtk.SelectionMode.NONE)
        flow_box.set_max_children_per_line(6)
        flow_box.set_homogeneous(True)

        for trending_applcation_loop in trending_application_list:
            hbox = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)

            icon_name = trending_applcation_loop.getIcon()
            
            image = Gtk.Image.new_from_file(icon_name)
            image.set_pixel_size(48)
            hbox.append(image)

            text_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
            text_box.set_valign(Gtk.Align.CENTER)

            title_label = Gtk.Label(label=trending_applcation_loop.getName())
            title_label.set_halign(Gtk.Align.START)
            title_label.add_css_class('title')
            text_box.append(title_label)

            summary_label = Gtk.Label(label=trending_applcation_loop.getSummary())
            summary_label.set_halign(Gtk.Align.START)
            summary_label.add_css_class('caption')
            text_box.append(summary_label)

            hbox.append(text_box)

            button = Gtk.Button()
            button.set_child(hbox)
            button.connect('clicked', self._on_app_clicked, trending_applcation_loop.id, appstream_repository)
            flow_box.append(button)

        pref_group_trending_apps.add(flow_box)

        

         

        pref_page_home.add(pref_group_trending_apps)
        toolbar_view.set_content(pref_page_home)



        return toolbar_view
    
    def _on_app_clicked(self, _button, app_id: str, appstream_repository: AppstreamRepository):
        app = appstream_repository.get_by_id(app_id)
        if app:
            self.navigation_view.push(AppstreamPage(app))

    

    def _on_close_request(self, _window):
     
        return False  # Allow window to close

     

class AppWindow(Adw.Application):
    def __init__(self):
        super().__init__(application_id="org.dupot.easyflatpak")

    def do_activate(self):
        win = MainWindow(application=self)
        win.present()
