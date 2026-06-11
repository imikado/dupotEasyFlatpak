from domain.UseCase.sync_database_from_api_uc import SyncDatabaseFromApiUc
from domain.UseCase.update_database_from_api_uc import UpdateDatabaseFromApiUc
from domain.conf.path_conf import PathConf
from infrastructure.api.flathub_api import FlathubApi
from infrastructure.api.system_api import SystemApi
from infrastructure.repository.appstream_repository import AppstreamRepository
from gi.repository import GLib

path_conf = PathConf()
path_conf.set_data_path(GLib.get_user_data_dir())

sync_database_from_api = SyncDatabaseFromApiUc(FlathubApi(), AppstreamRepository(), SystemApi())
sync_database_from_api.process()

update_database_from_api = UpdateDatabaseFromApiUc(
    FlathubApi(), AppstreamRepository(), SystemApi()
)
update_database_from_api.process()
