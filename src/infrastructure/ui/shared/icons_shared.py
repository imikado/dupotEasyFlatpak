import os
import gi

gi.require_version("Gtk", "4.0")
gi.require_version("Gdk", "4.0")

from gi.repository import Gtk, Gdk

_ICONS_DIR = os.path.normpath(os.path.join(
    os.path.dirname(os.path.abspath(__file__)),
    "..", "..", "..", "assets", "ui_icons",
))


class IconsShared:

    _instance: "IconsShared | None" = None

    # Navigation
    ICON_HOME = "easyflatpak-home-symbolic"
    ICON_CATEGORIES = "easyflatpak-categories-symbolic"
    ICON_BUNDLES = "easyflatpak-bundles-symbolic"
    ICON_INSTALLED = "easyflatpak-installed-symbolic"
    ICON_UPDATES = "easyflatpak-updates-symbolic"
    ICON_PENDING = "easyflatpak-pending-symbolic"

    # Actions
    ICON_EDITRECIPE = "easyflatpak-edit-recipe-symbolic"
    ICON_INFO = "easyflatpak-info-symbolic"
    ICON_EDIT = "easyflatpak-edit-symbolic"
    ICON_CHECKMARK = "easyflatpak-checkmark-symbolic"
    ICON_MENU = "easyflatpak-menu-symbolic"
    ICON_SEARCH = "easyflatpak-search-symbolic"

    # Links
    ICON_HOMEPAGE = "easyflatpak-homepage-symbolic"
    ICON_BUGTRACKER = "easyflatpak-bugtracker-symbolic"
    ICON_DONATION = "easyflatpak-donation-symbolic"

    # Categories
    ICON_DEVELOPMENT = "easyflatpak-development-symbolic"
    ICON_GAME = "easyflatpak-game-symbolic"
    ICON_GRAPHICS = "easyflatpak-graphics-symbolic"

    icon_ref = {
        "AudioVideo": "easyflatpak-audiovideo-symbolic",
        "Development": "easyflatpak-development-symbolic",
        "Education": "easyflatpak-education-symbolic",
        "Game": "easyflatpak-game-symbolic",
        "Graphics": "easyflatpak-graphics-symbolic",
        "Network": "easyflatpak-network-symbolic",
        "Office": "easyflatpak-office-symbolic",
        "Science": "easyflatpak-science-symbolic",
        "System": "easyflatpak-system-symbolic",
        "Utility": "easyflatpak-utility-symbolic",
        # navigation / action keys kept for backwards compat
        "CheckMark": ICON_CHECKMARK,
        "Edit": ICON_EDIT,
        "Info": ICON_INFO,
        "Edit-recipe": ICON_EDITRECIPE,
        "Home": ICON_HOME,
        "Categories": ICON_CATEGORIES,
        "Bundles": ICON_BUNDLES,
        "Installed": ICON_INSTALLED,
        "Updates": ICON_UPDATES,
        "Pending": ICON_PENDING,
        "Homepage": ICON_HOMEPAGE,
        "Bugtracker": ICON_BUGTRACKER,
        "Donation": ICON_DONATION,
    }

    _theme_registered: bool = False

    def __new__(cls, *_args, **_kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    @classmethod
    def _ensure_theme_registered(cls) -> None:
        if cls._theme_registered:
            return
        display = Gdk.Display.get_default()
        if display:
            Gtk.IconTheme.get_for_display(display).add_search_path(_ICONS_DIR)
            cls._theme_registered = True

    def get_icon_by_name(self, name: str) -> Gtk.Image:
        self._ensure_theme_registered()
        icon_name = self.find_icon_name_available(name)
        return Gtk.Image.new_from_icon_name(icon_name)

    def find_icon_name_available(self, name: str) -> str:
        return self.icon_ref.get(name, name)
