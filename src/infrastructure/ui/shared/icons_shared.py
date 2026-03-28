import gi

gi.require_version("Gtk", "4.0")

from gi.repository import Gtk, Gdk


class IconsShared:

    _instance: "IconsShared | None" = None

    ICON_HOME = "Home"
    ICON_CATEGORIES = "Categories"
    ICON_BUNDLES = "Bundles"
    ICON_INSTALLED = "Installed"
    ICON_UPDATES = "Updates"
    ICON_PENDING = "Pending"
    ICON_EDITRECIPE = "Edit-recipe"
    ICON_INFO = "Info"
    ICON_EDIT = "Edit"
    ICON_CHECKMARK = "CheckMark"

    ICON_DEVELOPMENT = "Development"
    ICON_GAME = "Game"
    ICON_GRAPHICS = "Graphics"

    icon_ref = {
        "CheckMark": [
            "object-select-symbolic",
            "emblem-ok-symbolic",
            "checkmark-symbolic",
        ],
        "Edit": [
            "document-edit-symbolic",
            "edit-symbolic",
            "accessories-text-editor-symbolic",
        ],
        "Info": [
            "dialog-information-symbolic",
            "information-symbolic",
            "help-about-symbolic",
        ],
        "Edit-recipe": [
            "preferences-system-symbolic",
            "settings-symbolic",
            "system-run-symbolic",
        ],
        "Home": ["go-home-symbolic", "user-home-symbolic", "start-here-symbolic"],
        "Categories": [
            "view-app-grid-symbolic",
            "applications-all-symbolic",
            "applications-system-symbolic",
        ],
        "Bundles": ["folder-symbolic", "folder", "document-open-symbolic"],
        "Installed": ["drive-harddisk-symbolic", "computer-symbolic", "drive-harddisk"],
        "Updates": [
            "software-update-available-symbolic",
            "software-update-urgent-symbolic",
            "view-refresh-symbolic",
        ],
        "Pending": [
            "emblem-downloads-symbolic",
            "folder-download-symbolic",
            "document-save-symbolic",
        ],
        "AudioVideo": [
            "applications-multimedia-symbolic",
            "media-playback-start-symbolic",
            "audio-x-generic-symbolic",
            "multimedia-player-symbolic",
        ],
        "Development": [
            "applications-development-symbolic",
            "emblem-developer-symbolic",
            "applications-development-symbolic",
            "utilities-terminal-symbolic",
        ],
        "Education": [
            "applications-science-symbolic",
            "accessories-dictionary-symbolic",
            "accessories-text-editor-symbolic",
            "format-text-bold-symbolic",
        ],
        "Game": [
            "applications-games-symbolic",
            "input-gaming-symbolic",
            "applications-games-symbolic",
            "joystick-symbolic",
        ],
        "Graphics": [
            "applications-graphics-symbolic",
            "image-x-generic-symbolic",
            "applications-graphics-symbolic",
            "image-missing-symbolic",
        ],
        "Network": [
            "applications-internet-symbolic",
            "network-workgroup-symbolic",
            "network-server-symbolic",
            "network-wired-symbolic",
        ],
        "Office": [
            "x-office-document-symbolic",
            "office-calendar-symbolic",
            "document-new-symbolic",
        ],
        "Science": [
            "applications-engineering-symbolic",
            "applications-science-symbolic",
            "utilities-system-monitor-symbolic",
            "computer-symbolic",
        ],
        "System": [
            "applications-system-symbolic",
            "emblem-system-symbolic",
            "preferences-system-symbolic",
            "system-run-symbolic",
        ],
        "Utility": [
            "applications-utilities-symbolic",
            "accessories-calculator-symbolic",
            "applications-utilities-symbolic",
            "system-run-symbolic",
        ],
    }

    def __new__(cls, *_args, **_kwargs):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
        return cls._instance

    def get_icon_by_name(self, name: str):
        icon_name = self.find_icon_name_available(name)
        return Gtk.Image.new_from_icon_name(icon_name)

    def find_icon_available_in_list(self, name_list: list[str]) -> str:
        theme = Gtk.IconTheme.get_for_display(Gdk.Display.get_default())
        for name in name_list:
            if theme.has_icon(name):
                return name
        return name_list[0]

    def find_icon_name_available(self, name: str) -> str:
        return self.find_icon_available_in_list(self.icon_ref.get(name))
