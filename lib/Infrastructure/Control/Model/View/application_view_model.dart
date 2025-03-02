import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/command_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/flathub_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/recipe_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';
import 'package:logging/logging.dart';

class ApplicationViewModel {
  static final _logger = Logger('ApplicationViewModel');

  Future<ApplicationEntity> getApplicationEntity(String appId) async {
    ApplicationRepository appStreamFactory = ApplicationRepository();

    ApplicationEntity applicationEntity =
        await appStreamFactory.findApplicationEntityById(appId);

    if (applicationEntity.lastUpdateIsOlderThan(7)) {
      _logger.info('Updating from API');
      if (!await FlathubApi(applicationRepository: appStreamFactory)
          .updateAppStream(appId)) {
        applicationEntity.isEmpty = true;

        await ApplicationRepository().deleteApplicationId(appId);
        return applicationEntity;
      }

      applicationEntity =
          await appStreamFactory.findApplicationEntityById(appId);
    }

    applicationEntity.isAlreadyInstalled = await checkAlreadyInstalled(appId);
    if (applicationEntity.isAlreadyInstalled) {
      applicationEntity.isScopeUser = await isInstalledInUserScope(appId);
    }

    applicationEntity.isOverrided = await checkIsOverrided(appId);

    applicationEntity.hasRecipe = await checkHasRecipe(appId);

    return applicationEntity;
  }

  Future<bool> checkHasUpdate(String applicationId) async {
    if (CommandApi().hasUpdateAvailableByAppId(applicationId)) {
      return true;
    }
    return false;
  }

  Future<bool> checkHasRecipe(String applicationId) async {
    List<String> recipeList = await RecipeApi().getApplicationList();
    if (recipeList.contains(applicationId.toLowerCase())) {
      return true;
    }
    return false;
  }

  Future<bool> checkAlreadyInstalled(String applicationId) async {
    FlatpakApplication result =
        await CommandApi().isApplicationAlreadyInstalled(applicationId);

    return result.isInstalled;
  }

  Future<bool> isInstalledInUserScope(String applicationId) async {
    return await CommandApi().isApplicationInstalledInScopeUser(applicationId);
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
