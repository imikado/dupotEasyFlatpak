from domain.conf.path_conf import PathConf
from domain.contract.api_cache_repository_contract import ApiCacheRepositoryContract
from domain.contract.appstream_repository_contract import AppstreamRepositoryContract
from domain.contract.flathub_api_contract import FlathubApiContract
from domain.contract.flatpak_api_contract import FlatpakApiContract
from domain.contract.flatpakrepo_repository_contract import FlatpakRepoRepositoryContract
from domain.contract.oci_api_contract import OciApiContract
from domain.contract.system_api_contract import SystemApiContract
from domain.entity.flatpakrepo_entity import FlatpakRepoEntity


class UpdateDatabaseFromApiUc:

    REPO_FLATHUB="flathub"

    LAST_SYNC_MAX_DAYS = 3

    _flathub_api: FlathubApiContract
    _appstream_repository: AppstreamRepositoryContract
    _system_api: SystemApiContract
    _api_cache_repository: ApiCacheRepositoryContract
    _flatpakrepo_repository:FlatpakRepoRepositoryContract
    _flatpak_api:FlatpakApiContract
    _oci_api:OciApiContract
    _lang:str

    def __init__(
        self,
        flathub_api: FlathubApiContract,
        appstream_repository: AppstreamRepositoryContract,
        system_api: SystemApiContract,
        api_cache_repository: ApiCacheRepositoryContract,
        flatpakrepo_repository:FlatpakRepoRepositoryContract,
        flatpak_api:FlatpakApiContract,
        lang:str,
        oci_api: OciApiContract,
    ):
        self._flathub_api = flathub_api
        self._appstream_repository = appstream_repository
        self._system_api = system_api
        self._api_cache_repository = api_cache_repository
        self._flatpakrepo_repository=flatpakrepo_repository
        self._flatpak_api=flatpak_api
        self._lang=lang
        self._oci_api = oci_api

    def process(self):

        if not self.should_sync_api():
            return

        print("need to sync from api")

        try:
            self._process()
        except Exception as e:
            import traceback

            print(f"[sync] ERROR: {e}")
            traceback.print_exc()

    def _process(self):

        app_id_to_check_in_db_list = []

        api_cache_entity = self._api_cache_repository.get_by_id(
            ApiCacheRepositoryContract.ID_APPS_OF_WEEK
        )

        app_id_of_the_week_list = api_cache_entity.get_app_id_list()
        for app_id_of_the_week_loop in app_id_of_the_week_list:
            app_id_to_check_in_db_list.append(app_id_of_the_week_loop)

        recently_raw_appstream_list = self._flathub_api.get_added_appstreams()
        for recently_raw_appstream_loop in recently_raw_appstream_list:
            app_id_to_check_in_db_list.append(recently_raw_appstream_loop["app_id"])


        

        app_id_list_already_stored = []

        appstream_list_already_stored = self._appstream_repository.get_list_by_id_list(
            app_id_to_check_in_db_list
        )
        for appstream_loop in appstream_list_already_stored:
            app_id_list_already_stored.append(appstream_loop.id.lower())

        icons_path = PathConf().get_icons_path()

        for recently_raw_appstream_loop in recently_raw_appstream_list:

            id_loop: str = recently_raw_appstream_loop["app_id"]

            if id_loop.lower() not in app_id_list_already_stored:
                self._appstream_repository.insert_from_raw_object(
                    recently_raw_appstream_loop
                )
            else:
                self._appstream_repository.update_name_summary_by_id(
                    id_loop,
                    recently_raw_appstream_loop["name"],
                    recently_raw_appstream_loop["summary"],
                )

            icon_url = recently_raw_appstream_loop.get("icon", "")
            if icon_url:
                icon_path = f"{icons_path}/{id_loop.lower()}.png"
                if not self._system_api.file_exists(icon_path):
                    self._system_api.download_remote_file_to(icon_url, icon_path)

        for app_id_of_the_week_loop in app_id_of_the_week_list:
            if app_id_of_the_week_loop.lower() not in app_id_list_already_stored:

                self._appstream_repository.insert_missing_app_id(
                    app_id_of_the_week_loop,
                    self.REPO_FLATHUB
                )

            detail = self._flathub_api.get_appstream_by_id(app_id_of_the_week_loop)
            if detail:
                self._appstream_repository.update_from_raw_object_with_id(
                    app_id_of_the_week_loop, detail
                )

        self.process_for_other_repos()

        self.update_sync_api(self._lang)

    def process_for_other_repos(self):
        app_id_list_already_stored = []

        app_id_to_check_in_db_list = []

        flatpakrepo_list: list[FlatpakRepoEntity] = self._flatpakrepo_repository.get_all_entities()
        remote_app_list_by_repo_id = {}
        repo_url_by_id = {}
        for flatpak_repo_loop in flatpakrepo_list:
            repo_id_loop = flatpak_repo_loop.getId()
            if repo_id_loop == self.REPO_FLATHUB:
                continue

            repo_url_by_id[repo_id_loop] = flatpak_repo_loop.getUrl()
            remote_app_found_list = self._flatpak_api.get_remote_app_list(repo_id_loop)
            remote_app_list_by_repo_id[repo_id_loop] = remote_app_found_list
            for remote_app_loop in remote_app_found_list:
                app_id_to_check_in_db_list.append(remote_app_loop.getId())


        appstream_list_already_stored = self._appstream_repository.get_list_by_id_list(
            app_id_to_check_in_db_list
        )
        for appstream_loop in appstream_list_already_stored:
            app_id_list_already_stored.append(appstream_loop.id.lower())


        for repo_id_loop, remote_app_found_list in remote_app_list_by_repo_id.items():
            repo_url = repo_url_by_id.get(repo_id_loop, "")
            for remote_app_loop in remote_app_found_list:
                remote_app_id_loop = remote_app_loop.getId()
                if remote_app_id_loop.lower() not in app_id_list_already_stored:
                    if not self._try_enrich_from_oci(remote_app_id_loop, repo_id_loop, repo_url):
                        self._appstream_repository.insert_missing_remote_app_id(
                            remote_app_id_loop,remote_app_loop.getName(), repo_id_loop
                        )
                    app_id_list_already_stored.append(remote_app_id_loop.lower())
                else:
                    # Already tracked (e.g. from Flathub) — record that this
                    # repo also serves it instead of ignoring the match.
                    self._appstream_repository.add_flatpak_repo_id(
                        remote_app_id_loop, repo_id_loop
                    )

    def _try_enrich_from_oci(self, app_id: str, repo_id: str, repo_url: str) -> bool:
        # Only OCI-based repos (registries) embed appstream/icon data this
        # way — a plain ostree repo's apps stay on the bare-row fallback.
        if not repo_url.startswith("oci+"):
            return False

        enrichment = self._oci_api.get_enrichment_by_app_id(repo_url, app_id)
        if not enrichment:
            return False

        raw_obj = enrichment.get("raw_obj")
        if not raw_obj or not raw_obj.get("name"):
            return False

        self._appstream_repository.insert_from_raw_object(raw_obj, repo_id)
        self._appstream_repository.update_from_raw_object_with_id(app_id, raw_obj)

        icon_bytes = enrichment.get("icon_bytes")
        if icon_bytes:
            icon_path = f"{PathConf().get_icons_path()}/{app_id.lower()}.png"
            self._system_api.write_binary_file(icon_path, icon_bytes)

        return True


    def should_sync(self, last_update) -> bool:

        if (
            last_update + self.LAST_SYNC_MAX_DAYS * 60 * 60 * 24
        ) < self._system_api.get_datetime_current_timestamp():

            return True
        return False

    def should_sync_api(self) -> bool:
        api_cache_parameter_entity = self._api_cache_repository.get_by_id(
            ApiCacheRepositoryContract.ID_PARAMETERS
        )

        if(api_cache_parameter_entity.get_api_last_lang()!=self._lang):
            return True

        last_timestamp_update = api_cache_parameter_entity.get_api_last_sync_timestamp()
        return self.should_sync(last_timestamp_update)

    def update_sync_api(self,lang:str):
        api_cache_parameter_entity = self._api_cache_repository.get_by_id(
            ApiCacheRepositoryContract.ID_PARAMETERS
        )
        api_cache_parameter_entity.update_api_last_sync_timestamp(
            self._system_api.get_datetime_current_timestamp(),
            lang
        )

        self._api_cache_repository.update_by_id(
            ApiCacheRepositoryContract.ID_PARAMETERS,
            api_cache_parameter_entity.get_content_as_object(),
        )
