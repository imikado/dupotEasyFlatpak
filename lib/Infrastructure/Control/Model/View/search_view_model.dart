import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';

class SearchViewModel {
  Future<List<ApplicationEntity>> getApplicationEntityListBySearch(
      String search) async {
    ApplicationRepository appStreamFactory = ApplicationRepository();

    List<ApplicationEntity> applicationEntityList = [];
    if (search.length > 3) {
      return await appStreamFactory.findListApplicationEntityBySearch(search);
    }

    return applicationEntityList;
  }
}
