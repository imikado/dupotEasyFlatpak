import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/flathub_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/recipe_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';

class ApplicationViewModel {
  Future<ApplicationEntity> getApplicationEntity(String appId) async {
    ApplicationRepository appStreamFactory = ApplicationRepository();

    ApplicationEntity applicationEntity;

    applicationEntity = await appStreamFactory.findApplicationEntityById(appId);

    applicationEntity.isAlreadyInstalled = checkAlreadyInstalled(appId);
    if (applicationEntity.isAlreadyInstalled) {
      applicationEntity.isScopeUser = isInstalledInUserScope(appId);
    }
    applicationEntity.hasRecipe = await checkHasRecipe(appId);

    return applicationEntity;
  }

  Future<ApplicationEntity> updateDataForApplicationIfNeeded(
      ApplicationEntity applicationEntity) async {
    String appId = applicationEntity.id;

    ApplicationRepository appStreamFactory = ApplicationRepository();

    if (applicationEntity.lastUpdateIsOlderThan(7)) {
      String lastVersionId = applicationEntity.getLastVersionId();

      await FlathubApi()
          .updateAppStreamIfLastVesionIsDifferent(appId, lastVersionId);

      applicationEntity =
          await appStreamFactory.findApplicationEntityById(appId);
    }

    //applicationEntity.isOverrided = await checkIsOverrided(appId);

    return applicationEntity;
  }

  Future<bool> checkHasUpdate(String applicationId) async {
    if (CommandApi().hasUpdateAvailableByAppId(applicationId)) {
      return true;
    }
    return false;
  }

  Future<bool> checkHasRecipe(String applicationId) async {
    return await CommandApi().checkHasRecipe(applicationId);
  }

  bool checkAlreadyInstalled(String applicationId) {
    FlatpakApplication result =
        CommandApi().isApplicationAlreadyInstalled(applicationId);

    return result.isInstalled;
  }

  bool isInstalledInUserScope(String applicationId) {
    return CommandApi().isApplicationInstalledInScopeUser(applicationId);
  }

  Future<bool> checkIsOverrided(String applicationId) async {
    if (!await RecipeApi().hasApplication(applicationId)) {
      return false;
    }

    FlatpakOverrideApplication result =
        await CommandApi().isApplicationOverrided(applicationId);
    return result.isOverrided;
  }
}
