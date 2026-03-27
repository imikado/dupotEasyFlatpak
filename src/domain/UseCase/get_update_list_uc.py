from domain.contract.flatpak_api_contract import FlatpakApiContract
from domain.entity.installed_version_entity import InstalledVersionEntity
from domain.entity.update_available_entity import UpdateAvailableEntity


class GetUpdateListUc:

    flatpak_api: FlatpakApiContract

    def __init__(self, flatpak_api: FlatpakApiContract):
        self.flatpak_api = flatpak_api
        pass

    def get_list(self) -> list[UpdateAvailableEntity]:

        indexed_installed_list = self.get_indexed_installed_list(
            self.flatpak_api.get_installed_list()
        )

        updates_available_list = self.flatpak_api.get_available_update_list()
        for update_available_loop in updates_available_list:
            if update_available_loop.app_id in indexed_installed_list:
                installed_version = indexed_installed_list[update_available_loop.app_id]

                if (
                    installed_version != ""
                    and installed_version == update_available_loop.version
                ):
                    updates_available_list.remove(update_available_loop)
                    continue

                update_available_loop.set_current_version(installed_version)

        return updates_available_list

    def get_indexed_installed_list(
        self, installed_list: list[InstalledVersionEntity]
    ) -> dict:

        indexed_installed_list = {}

        for installed_loop in installed_list:
            indexed_installed_list[installed_loop.app_id] = installed_loop.version

        return indexed_installed_list
