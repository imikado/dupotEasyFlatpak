# dupotEasyFlatpak

Help to install flatpak easier

## Add new application's recipie

This application use json files to setup the way to install it.

These files are stored in assets/recipies folder

### Create a recipie
In the application, you can on top right click on Add button

You will have a form to setup application name without space or accent

And bellow the JSON setup

For example create heroic game launcher recipie

Application name: heroic

Application json setup recipie
```json
{
  "title": "Heroic Games Launcher",
  "description": "An Open Source Epic Games, GOG and Amazon Prime Games Launcher.",
  "flatpak": "com.heroicgameslauncher.hgl",

  "flatpakPermissionToOverrideList": [
    {
      "label": "Veuilez selectionner le repertoire contenant vos jeux",
      "type": "filesystem"
    }
  ]
}
```

The application will create a file in ~/Documents/EasyFlatpak/heroic.json



Title: the application's name

Description: the description

Flatpak: the flatpak id of the application

flatpakPermissionToOverrideList: list of action to override after the flatpak installation

You have for the moment two type: filesystem and filesystem_noprompt

filesystem: ask the user to select a folder with a label to explain what folder to select

filesystem_noprompt: this will overirde the filesystem with a defined value, for example: discord need to share home

### Enable recipie's application

To list this application recipie, you have to edit recicipes.json

Edit assets/recipies.json

```json
["steam", "bottles", "heroic", "lutris", "discord"]
```
