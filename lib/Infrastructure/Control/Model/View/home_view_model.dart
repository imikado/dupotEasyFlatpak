import 'package:dupot_easy_flatpak/Domain/Entity/db/application_entity.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Api/flathub_api.dart';
import 'package:dupot_easy_flatpak/Infrastructure/Repository/application_repository.dart';

class HomeViewModel {
  late ApplicationRepository applicationRepository;
  late List<String> categoryIdList = [];

  HomeViewModel() {
    applicationRepository = ApplicationRepository();
  }

  Future<List<List<ApplicationEntity>>> getApplicationEntityList() async {
    List<List<ApplicationEntity>> applicationEntityListList = [];

    List<String> localCategoryIdList = await getCategoryIdList();

    for (String categoryIdLoop in localCategoryIdList) {
      List<ApplicationEntity> appStreamList = await applicationRepository
          .findListApplicationEntityByCategoryOrderedAndLimited(
              categoryIdLoop, 9);

      applicationEntityListList.add(appStreamList);
    }

    return applicationEntityListList;
  }

  Future<List<ApplicationEntity>>
      getUpdatedApplicationEntityListFromApi() async {
    FlathubApi flathubApi = FlathubApi();

    List<String> applicationIdList =
        await flathubApi.getUpdatedRawApplicationIdList();

    return await applicationRepository
        .findListApplicationEntityByIdList(applicationIdList);
  }

  Future<List<ApplicationEntity>>
      getPopularApplicationEntityListFromApi() async {
    FlathubApi flathubApi = FlathubApi();

    List<String> applicationIdList =
        await flathubApi.getPopularRawApplicationIdList();

    return await applicationRepository
        .findListApplicationEntityByIdList(applicationIdList);
  }

  Future<List<ApplicationEntity>>
      getTrendingApplicationEntityListFromApi() async {
    FlathubApi flathubApi = FlathubApi();

    List<String> applicationIdList =
        await flathubApi.getTrendingRawApplicationIdList();

    return await applicationRepository
        .findListApplicationEntityByIdList(applicationIdList);
  }

  Future<List<String>> getCategoryIdList() async {
    if (categoryIdList.isEmpty) {
      categoryIdList = await applicationRepository.findAllCategoryList();
    }
    return categoryIdList;
  }
}
