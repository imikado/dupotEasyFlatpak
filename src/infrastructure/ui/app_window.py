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


        appstream_repository = AppstreamRepository()

        get_home_content_uc = GetHomeContentUC(ApiCacheRepository(), appstream_repository, FlathubApi())

        #trending
        trending_application_list = get_home_content_uc.get_trending_appstream_list()
        flow_box = self._get_application_list_widget(trending_application_list, appstream_repository)

        pref_group_trending_apps = Adw.PreferencesGroup()
        pref_group_trending_apps.set_title(_('Trending apps'))
        pref_group_trending_apps.add(flow_box)

        pref_page_home.add(pref_group_trending_apps)


        #popular
        popular_application_list = get_home_content_uc.get_popular_appstream_list()
        flow_box = self._get_application_list_widget(popular_application_list, appstream_repository)

        pref_group_trending_apps = Adw.PreferencesGroup()
        pref_group_trending_apps.set_title(_('Popular apps'))
        pref_group_trending_apps.add(flow_box)

        pref_page_home.add(pref_group_trending_apps)

        #updated
        popular_application_list = get_home_content_uc.get_updated_appstream_list()
        flow_box = self._get_application_list_widget(popular_application_list, appstream_repository)

        pref_group_trending_apps = Adw.PreferencesGroup()
        pref_group_trending_apps.set_title(_('Recently updated apps'))
        pref_group_trending_apps.add(flow_box)

        pref_page_home.add(pref_group_trending_apps)



        toolbar_view.set_content(pref_page_home)



        return toolbar_view
    
    def _get_application_list_widget(self, application_list, appstream_repository):
        flow_box = Gtk.FlowBox()
        flow_box.set_selection_mode(Gtk.SelectionMode.NONE)
        flow_box.set_max_children_per_line(6)
        flow_box.set_min_children_per_line(3)
        flow_box.set_homogeneous(True)
        flow_box.set_row_spacing(8)
        flow_box.set_column_spacing(8)

        for app in application_list:
            card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
            card.set_halign(Gtk.Align.CENTER)
            card.set_margin_top(12)
            card.set_margin_bottom(12)
            card.set_margin_start(8)
            card.set_margin_end(8)

            image = Gtk.Image.new_from_file(app.getIcon())
            image.set_pixel_size(64)
            image.set_halign(Gtk.Align.CENTER)
            card.append(image)

            title_label = Gtk.Label(label=app.getName())
            title_label.set_halign(Gtk.Align.CENTER)
            title_label.set_wrap(True)
            title_label.set_max_width_chars(12)
            title_label.add_css_class('caption')
            card.append(title_label)

            button = Gtk.Button()
            button.add_css_class('card')
            button.set_child(card)
            button.connect('clicked', self._on_app_clicked, app.id, appstream_repository)
            flow_box.append(button)

        return flow_box

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
