#!/usr/bin/env python3

from infrastructure.ui.app_window import AppWindow

import gettext



def main():
    # Set the local directory
    appname = 'nix-samba'
    localedir = './infrastructure/locales'

    # Set up Gettext
    en_i18n = gettext.translation(appname, localedir, fallback=True, languages=['en','fr'])

    # Create the "magic" function
    en_i18n.install()


    app = AppWindow()
    app.run(None)


if __name__ == "__main__":
    main()
