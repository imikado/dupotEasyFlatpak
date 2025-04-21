import 'package:dupot_easy_flatpak/Domain/Entity/recipe/permission_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/recipe/permission_overrided_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/recipe/recipe_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/recipe_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Entity/override_form_control.dart';
import 'package:ini/ini.dart';

class OverrideControl {
  Config overrideConfig = Config();

  static const String constFileSystems = 'filesystems';
  static const String constEnvs = 'envs';

  List<String> overridedFileSystemList = [];
  int overridedFileSystemIndex = 0;

  List<String> overridedEnvList = [];
  int overridedEnvIndex = 0;

  Future<List<OverrideFormControl>> getOverrideControlList(
      applicationId) async {
    await loadOverrideConfig(applicationId);

    RecipeEntity recipe = await RecipeApi().getApplication(applicationId);

    List<OverrideFormControl> overrideFormControlList = [];

    List<PermissionEntity> recipePermissionList =
        recipe.getFlatpakPermissionToOverrideList();

    for (PermissionEntity recipePermissionLoop in recipePermissionList) {
      if (recipePermissionLoop.isInstallFlatpakYesNo()) {
        continue;
      }
      OverrideFormControl overrideFormControlLoop = OverrideFormControl();
      overrideFormControlLoop.setLabel(recipePermissionLoop.label);
      overrideFormControlLoop.setType(recipePermissionLoop.type);

      if (overrideFormControlLoop.isTypeFileSystem()) {
        String textValue = await getOverridedConfig(recipePermissionLoop.type);

        overrideFormControlLoop.setValue(textValue);
      } else if (overrideFormControlLoop.isTypeEnv()) {
        overrideFormControlLoop
            .setValue(recipePermissionLoop.getValue().toString());
        overrideFormControlLoop
            .setSubValueYes(recipePermissionLoop.subValueYes.toString());
        overrideFormControlLoop
            .setSubValueNo(recipePermissionLoop.subValueNo.toString());

        if (await hasOverridedConfig(
            recipePermissionLoop.type, recipePermissionLoop.value.toString())) {
          String textValue = await getOverridedSubConfig(
              recipePermissionLoop.type, recipePermissionLoop.value.toString());

          overrideFormControlLoop.setValue(textValue);

          if (textValue == recipePermissionLoop.subValueYes) {
            overrideFormControlLoop.boolValue = true;
          }
        } else {
          overrideFormControlLoop.boolValue = false;
        }
      }

      overrideFormControlList.add(overrideFormControlLoop);
    }

    return overrideFormControlList;
  }

  Future<List<OverrideFormControl>> getOverrideControlWithImportedConfigList(
      applicationId,
      List<PermissionOverridedEntity> importedPermissionEntityList) async {
    RecipeEntity recipe = await RecipeApi().getApplication(applicationId);

    List<OverrideFormControl> overrideFormControlList = [];

    List<PermissionEntity> recipePermissionList =
        recipe.getFlatpakPermissionToOverrideList();

    for (PermissionEntity recipePermissionLoop in recipePermissionList) {
      OverrideFormControl overrideFormControlLoop = OverrideFormControl();
      overrideFormControlLoop.setLabel(recipePermissionLoop.label);

      String textValue = getValueFromImportedConfigByType(
          recipePermissionLoop.type,
          importedPermissionEntityList,
          recipePermissionLoop.getValue().toString());

      overrideFormControlLoop.setValue(textValue);

      overrideFormControlLoop.setType(recipePermissionLoop.type);

      overrideFormControlList.add(overrideFormControlLoop);
    }

    return overrideFormControlList;
  }

  String getValueFromImportedConfigByType(
      String type,
      List<PermissionOverridedEntity> permissionOverridedEntityList,
      String defaultValue) {
    for (PermissionOverridedEntity permissionOverridedEntityLoop
        in permissionOverridedEntityList) {
      if (permissionOverridedEntityLoop.type == type) {
        return permissionOverridedEntityLoop.value!;
      }
    }
    return defaultValue;
  }

  Future<List<OverrideFormControl>> getOverrideControlWithoutConfigList(
      applicationId) async {
    RecipeEntity recipe = await RecipeApi().getApplication(applicationId);

    List<OverrideFormControl> overrideFormControlList = [];

    List<PermissionEntity> recipePermissionList =
        recipe.getFlatpakPermissionToOverrideList();

    for (PermissionEntity recipePermissionLoop in recipePermissionList) {
      OverrideFormControl overrideFormControlLoop = OverrideFormControl();
      overrideFormControlLoop.setLabel(recipePermissionLoop.label);

      String textValue = recipePermissionLoop.getValue().toString();

      overrideFormControlLoop.setValue(textValue);

      overrideFormControlLoop.setType(recipePermissionLoop.type);

      overrideFormControlList.add(overrideFormControlLoop);
    }

    return overrideFormControlList;
  }

  Future<void> loadOverrideConfig(applicationId) async {
    FlatpakOverrideApplication flatpakOverrideApplication =
        await CommandApi().isApplicationOverrided(applicationId);

    overrideConfig = Config.fromStrings(
        flatpakOverrideApplication.flatpakOutput.toString().split("\n"));
  }

  Future<String> getOverridedConfig(String type) async {
    if (['filesystem_noprompt', 'filesystem'].contains(type)) {
      if (overridedFileSystemList.isEmpty) {
        overridedFileSystemList = overrideConfig
            .get('Context', constFileSystems)
            .toString()
            .split(';');
      }

      String overridedFileSystemFound =
          overridedFileSystemList[overridedFileSystemIndex];

      overridedFileSystemIndex++;

      return overridedFileSystemFound;
    } else if (['env_yesno', 'env'].contains(type)) {
      if (overridedFileSystemList.isEmpty) {
        overridedEnvList =
            overrideConfig.get('Context', constEnvs).toString().split(';');
      }

      String overridedEnvFound = overridedEnvList[overridedEnvIndex];

      overridedEnvIndex++;

      return overridedEnvFound;
    }

    throw Exception('getOverridedConfig for type "$type" Not implemented');
  }

  Future<String> getOverridedSubConfig(String type, String value) async {
    if (['env_yesno', 'env'].contains(type)) {
      return overrideConfig.get('Environment', value).toString();
    }

    throw Exception('getOverridedConfig for type "$type" Not implemented');
  }

  Future<bool> hasOverridedConfig(String type, String value) async {
    if (['filesystem_noprompt', 'filesystem'].contains(type)) {
      return overrideConfig.hasOption('Context', constFileSystems);
    } else if (['env_yesno', 'env'].contains(type)) {
      return overrideConfig.hasOption('Environment', value);
    }
    throw Exception('hasOverridedConfig for type "$type" Not implemented');
  }

  Future<void> save(String applicationId,
      List<OverrideFormControl> overrideFormControlList) async {
    await CommandApi().runProcess(
        'flatpak', ['override', '--user', '--reset', applicationId]);

    for (OverrideFormControl overrideFormControlLoop
        in overrideFormControlList) {
      if (overrideFormControlLoop.isTypeFileSystem()) {
        List<String> argList = [
          'override',
          '--user',
        ];

        argList.add('--filesystem=${overrideFormControlLoop.getValue()}');

        argList.add(applicationId);

        await CommandApi().runProcess('flatpak', argList);
      } else if (overrideFormControlLoop.isTypeInstallFlatpak()) {
        if (overrideFormControlLoop.boolValue) {
          List<String> argList = [
            'install',
            '-y',
            'flathub',
            UserSettingsEntity().getInstallationScope(),
          ];
          argList.add(overrideFormControlLoop.getValue());
          await CommandApi().runProcess('flatpak', argList);
        }
      } else if (overrideFormControlLoop.isTypeEnv()) {
        List<String> argList = [
          'override',
          '--user',
        ];

        argList.add(
            '--env=${overrideFormControlLoop.getValue()}=${overrideFormControlLoop.getSubValueYesNo()}');

        argList.add(applicationId);

        await CommandApi().runProcess('flatpak', argList);
      } else {
        throw Exception(
            'save overrideFormControlLoop.type ${overrideFormControlLoop.type} not implemented ');
      }
    }
  }
}
