from domain.conf.path_conf import PathConf
from domain.contract.system_api_contract import SystemApiContract
from domain.contract.user_settings_api_contract import UserSettingsApiContract
from domain.entity.user_settings_entity import UserSettingsEntity


class UserSettingsApi(UserSettingsApiContract):

    system_api: SystemApiContract

    def __init__(self, system_api: SystemApiContract):
        self.system_api = system_api

    def save(self):
        self.system_api.write_file(
            PathConf().get_user_settings_path(),
            UserSettingsEntity().get_json_string(),
        )
