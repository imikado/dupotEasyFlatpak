from domain.conf.path_conf import PathConf
from domain.contract.bundle_repository_contract import BundleRepositoryContract
from domain.entity.bundle_entity import BundleEntity
from infrastructure.api.system_api import SystemApi


class BundleRepository(BundleRepositoryContract):

    _bundle_list: list[BundleEntity] = []

    def __init__(self):
        super().__init__()

        system_api = SystemApi()
        raw_list = system_api.read_json_file_obj_list(
            PathConf().get_asset_bundles_path()
        )

        for raw_loop in raw_list:
            self._bundle_list.append(BundleEntity(raw_loop))

    def get_list(self) -> list[BundleEntity]:
        return self._bundle_list

    def get_by_id(self, id: str) -> BundleEntity:
        for bundle_loop in self._bundle_list:
            if bundle_loop.id == id:
                return bundle_loop
