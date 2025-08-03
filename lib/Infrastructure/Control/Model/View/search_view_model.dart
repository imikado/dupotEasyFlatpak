import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Domain/Entity/user_settings_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/flathub_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';

class SearchViewModel {
  late FlathubApi flathubApi;

  SearchViewModel() {
    flathubApi = FlathubApi();
  }

  Future<List<ApplicationEntity>> getApplicationEntityListBySearch(
      String search) async {
    ApplicationRepository appStreamFactory = ApplicationRepository();

    List<ApplicationEntity> applicationEntityList = [];
    if (search.length >= 3) {
      UserSettingsEntity userSettings = UserSettingsEntity();
      if (userSettings.getUseFlathubSearchApi()) {
        List<String> applicationIdList =
            await flathubApi.getApplicationIdListBySearch(search);

        return await appStreamFactory
            .findListApplicationEntityByIdList(applicationIdList);
      } else {
        return await appStreamFactory.findListApplicationEntityBySearch(search);
      }
    }

    return applicationEntityList;
  }
}
