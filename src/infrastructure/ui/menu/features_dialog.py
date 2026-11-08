import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Adw", "1")

from gi.repository import Gtk, Adw

from domain.entity.user_settings_entity import UserSettingsEntity
from infrastructure.api.system_api import SystemApi
from infrastructure.api.user_settings_api import UserSettingsApi
from infrastructure.ui.shared.icons_shared import IconsShared


class FeaturesDialog(Adw.Dialog):
    """Carousel tour of the application features.

    go_to_fn(target) is called by the "Open" button: target is either a
    view-stack page name ("home", "installed"…) or a window action ("win.tools").
    """

    def __init__(self, go_to_fn=None):
        super().__init__()
        self.set_title(_("Features"))
        self.set_content_width(560)
        self.set_content_height(520)
        self._go_to_fn = go_to_fn

        features = [
            (
                IconsShared.ICON_SEARCH,
                _("Browse & search Flathub"),
                _("Discover trending, popular and new applications on the Home tab, or search the whole Flathub catalog with the magnifier button at the top left."),
                _("Home tab · Search button"),
                "home",
            ),
            (
                IconsShared.ICON_CATEGORIES,
                _("Categories"),
                _("Explore applications grouped by category: games, graphics, development, office…"),
                _("Categories tab"),
                "categories",
            ),
            (
                IconsShared.ICON_BUNDLES,
                _("Bundles"),
                _("Install a curated group of applications in one go, for example everything needed for gaming or content creation."),
                _("Bundles tab"),
                "bundles",
            ),
            (
                IconsShared.ICON_CHECKMARK,
                _("Quick install"),
                _("Hover an application card and click its Install button to install it without opening its page. Several installs can run at the same time."),
                _("Any application card"),
                None,
            ),
            (
                IconsShared.ICON_EDITRECIPE,
                _("Recipes"),
                _("Some applications (Steam, Lutris, Heroic, Bottles…) need extra setup. \"Install with recipe\" configures them automatically, e.g. asking once for your games folder. Use \"Recipe overrides\" on the application page to adjust them later."),
                _("Application page · Parameters › Game path"),
                None,
            ),
            (
                IconsShared.ICON_PIN,
                _("Downgrade & pin"),
                _("An update broke an application? Roll back to a previous version with \"Downgrade\": the version is pinned and skipped by future updates."),
                _("Application page › Downgrade"),
                None,
            ),
            (
                IconsShared.ICON_UPDATES,
                _("Updates"),
                _("See available updates for applications and runtimes, select the ones you want or update everything at once."),
                _("Updates tab (visible when updates are available)"),
                None,
            ),
            (
                IconsShared.ICON_PENDING,
                _("Pending queue"),
                _("Follow every running install, update or maintenance task and display its full output log."),
                _("Pending tab (visible while tasks are running)"),
                None,
            ),
            (
                IconsShared.ICON_GITHUB,
                _("Install from anywhere"),
                _("Install a local .flatpak file, or the latest Flatpak published in a GitHub, GitLab or Codeberg release."),
                _("Installed tab · Menu › Install local Flatpak"),
                "installed",
            ),
            (
                IconsShared.ICON_EXPORT,
                _("Import / Export"),
                _("Back up the list of your installed applications (with scope and permission overrides) to a file, and restore it on another computer."),
                _("Installed tab · Menu › Import / Export"),
                "installed",
            ),
            (
                IconsShared.ICON_NETWORK,
                _("Repositories & parameters"),
                _("Choose user or system installation, filter by CPU architecture, add custom Flatpak repositories, change the theme and the language."),
                _("Menu › Parameters"),
                "win.parameters",
            ),
            (
                IconsShared.ICON_EDIT,
                _("Maintenance tools"),
                _("Clean the cache if text is displayed incorrectly, or repair your Flatpak installation after icon/permission errors."),
                _("Menu › Tools"),
                "win.tools",
            ),
        ]

        toolbar_view = Adw.ToolbarView()
        toolbar_view.add_top_bar(Adw.HeaderBar())

        self._carousel = Adw.Carousel()
        self._carousel.set_vexpand(True)
        self._carousel.set_hexpand(True)
        self._carousel.connect("page-changed", self._on_page_changed)
        for feature in features:
            self._carousel.append(self._build_slide(*feature))

        dots = Adw.CarouselIndicatorDots()
        dots.set_carousel(self._carousel)

        self._prev_btn = Gtk.Button(label=_("Previous"))
        self._prev_btn.add_css_class("pill")
        self._prev_btn.connect("clicked", lambda _b: self._scroll_by(-1))

        self._next_btn = Gtk.Button(label=_("Next"))
        self._next_btn.add_css_class("pill")
        self._next_btn.add_css_class("suggested-action")
        self._next_btn.connect("clicked", self._on_next_clicked)

        nav_box = Gtk.CenterBox()
        nav_box.set_margin_start(18)
        nav_box.set_margin_end(18)
        nav_box.set_margin_bottom(8)
        nav_box.set_start_widget(self._prev_btn)
        nav_box.set_center_widget(dots)
        nav_box.set_end_widget(self._next_btn)

        startup_check = Gtk.CheckButton(label=_("Show this page at startup"))
        startup_check.set_halign(Gtk.Align.CENTER)
        startup_check.set_margin_bottom(12)
        startup_check.set_active(UserSettingsEntity().show_features_at_startup)
        startup_check.connect("toggled", self._on_startup_toggled)

        content = Gtk.Box(orientation=Gtk.Orientation.VERTICAL)
        content.append(self._carousel)
        content.append(nav_box)
        content.append(startup_check)
        toolbar_view.set_content(content)
        self.set_child(toolbar_view)

        self._on_page_changed(self._carousel, 0)

    def _build_slide(self, icon_name, title, description, location, target):
        box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        box.set_valign(Gtk.Align.CENTER)
        box.set_hexpand(True)
        box.set_margin_start(36)
        box.set_margin_end(36)

        icon = IconsShared().get_icon_by_name(icon_name)
        icon.set_pixel_size(72)
        icon.set_margin_bottom(6)
        box.append(icon)

        title_label = Gtk.Label(label=title)
        title_label.add_css_class("title-1")
        title_label.set_wrap(True)
        title_label.set_justify(Gtk.Justification.CENTER)
        box.append(title_label)

        desc_label = Gtk.Label(label=description)
        desc_label.set_wrap(True)
        desc_label.set_justify(Gtk.Justification.CENTER)
        desc_label.set_max_width_chars(50)
        box.append(desc_label)

        location_label = Gtk.Label(label=location)
        location_label.add_css_class("dim-label")
        location_label.add_css_class("caption")
        location_label.set_wrap(True)
        location_label.set_justify(Gtk.Justification.CENTER)
        box.append(location_label)

        if target and self._go_to_fn:
            open_btn = Gtk.Button(label=_("Open"))
            open_btn.add_css_class("pill")
            open_btn.set_halign(Gtk.Align.CENTER)
            open_btn.set_margin_top(6)
            open_btn.connect("clicked", self._on_open_clicked, target)
            box.append(open_btn)

        return box

    def _scroll_by(self, delta: int):
        n = self._carousel.get_n_pages()
        index = int(round(self._carousel.get_position())) + delta
        if 0 <= index < n:
            self._carousel.scroll_to(self._carousel.get_nth_page(index), True)

    def _on_next_clicked(self, _btn):
        if int(round(self._carousel.get_position())) >= self._carousel.get_n_pages() - 1:
            self.close()
        else:
            self._scroll_by(1)

    def _on_page_changed(self, carousel, index):
        last = index >= carousel.get_n_pages() - 1
        self._prev_btn.set_sensitive(index > 0)
        self._next_btn.set_label(_("Close") if last else _("Next"))

    def _on_startup_toggled(self, check):
        UserSettingsEntity().show_features_at_startup = check.get_active()
        UserSettingsApi(SystemApi()).save()

    def _on_open_clicked(self, _btn, target):
        self.close()
        self._go_to_fn(target)
