#!/usr/bin/env python3
"""Refresh the shipped Flathub snapshot: src/assets/db/flathub_database.db + src/assets/icons.

Developer tool, run through ../syncFlathubApi.sh. Works headless on a staging
copy of the asset DB (the user's own data and custom repos are never touched),
then replaces the asset DB only if everything succeeded.
"""

import argparse
import builtins
import os
import shutil
import sqlite3
import sys
import tempfile
import time

builtins.__dict__.setdefault("_", lambda s: s)

from domain.conf.path_conf import PathConf
from domain.contract.api_cache_repository_contract import ApiCacheRepositoryContract


def log(msg: str):
    print(f"[{time.strftime('%H:%M:%S')}] {msg}", flush=True)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--full", action="store_true", help="also refresh details of every existing application (slow)")
    parser.add_argument("--prune", action="store_true", help="remove applications no longer on Flathub (and their icon)")
    parser.add_argument("--refresh-icons", action="store_true", help="re-download every icon, not only missing ones")
    parser.add_argument("--workers", type=int, default=8)
    parser.add_argument("--dry-run", action="store_true", help="only report what would change")
    args = parser.parse_args()

    path_conf = PathConf()
    asset_db = path_conf.get_asset_database_path()
    asset_icons = path_conf.get_asset_icons_path()

    staging = tempfile.mkdtemp(prefix="easyflatpak-sync-")
    data_dir = os.path.join(staging, PathConf.ID_PATH)
    os.makedirs(data_dir)
    shutil.copy2(asset_db, os.path.join(data_dir, PathConf.DATABASE_FILENAME))
    # icons are downloaded straight into the project
    os.symlink(os.path.abspath(asset_icons), os.path.join(data_dir, PathConf.ICON_PATH))
    path_conf.set_data_path(staging)

    # Imported after set_data_path: DatabaseApi opens the DB on first use.
    from domain.UseCase.get_home_content_uc import GetHomeContentUC
    from domain.UseCase.sync_database_from_api_uc import SyncDatabaseFromApiUc
    from domain.entity.user_settings_entity import UserSettingsEntity
    from infrastructure.api.database_api import DatabaseApi
    from infrastructure.api.flathub_api import FlathubApi
    from infrastructure.api.system_api import SystemApi
    from infrastructure.repository.api_cache_repository import ApiCacheRepository
    from infrastructure.repository.appstream_repository import AppstreamRepository

    # snapshot is always English; other languages are re-translated at first launch
    UserSettingsEntity().language = UserSettingsEntity.LANGUAGE_EN

    flathub_api, system_api = FlathubApi(), SystemApi()
    appstream_repository = AppstreamRepository()
    api_cache_repository = ApiCacheRepository()
    uc = SyncDatabaseFromApiUc(flathub_api, appstream_repository, system_api, args.workers, log)

    try:
        before = len(appstream_repository.get_all_app_id_list())
        icons_before = len(os.listdir(asset_icons))

        log("fetching Flathub application list")
        api_ids = uc.get_api_app_id_list()
        db_ids = {i.lower() for i in appstream_repository.get_all_app_id_list()}
        new_ids = [i for i in api_ids if i.lower() not in db_ids]
        removed_ids = uc.get_removed_app_id_list(api_ids)
        log(f"Flathub: {len(api_ids)} apps · database: {before} · new: {len(new_ids)} · gone from Flathub: {len(removed_ids)}")

        if args.dry_run:
            print("new:", ", ".join(new_ids[:50]) + (" …" if len(new_ids) > 50 else ""))
            print("gone:", ", ".join(removed_ids[:50]) + (" …" if len(removed_ids) > 50 else ""))
            return

        log("refreshing home lists (trending, popular, new, updated, apps of the week)")
        home_uc = GetHomeContentUC(api_cache_repository, appstream_repository, flathub_api, system_api, auto_sync=False)
        home_uc.update_parameters_in_cache(home_uc.get_entity_in_cache().update_home_api_updated_timestamp(0))
        home_uc.load()

        uc.process_insert_missing(api_ids)
        if args.full:
            uc.process_update()
        if args.prune and removed_ids:
            log(f"pruned: {uc.process_prune(removed_ids)}")
        log(f"icons downloaded: {uc.process_missing_icons(args.refresh_icons)}")
        for name in os.listdir(asset_icons):  # copies from a user data dir can be 0600
            os.chmod(os.path.join(asset_icons, name), 0o644)

        params = api_cache_repository.get_by_id(ApiCacheRepositoryContract.ID_PARAMETERS)
        params.update_api_last_sync_timestamp(system_api.get_datetime_current_timestamp(), "en")
        api_cache_repository.update_by_id(ApiCacheRepositoryContract.ID_PARAMETERS, params.get_content_as_object())

        after = len(appstream_repository.get_all_app_id_list())
        DatabaseApi().close()

        staging_db = os.path.join(data_dir, PathConf.DATABASE_FILENAME)
        with sqlite3.connect(staging_db) as con:
            if con.execute("PRAGMA integrity_check").fetchone()[0] != "ok":
                raise RuntimeError("integrity check failed, asset DB left untouched")
        con = sqlite3.connect(staging_db)
        con.execute("VACUUM")
        con.close()

        shutil.copy2(staging_db, asset_db + ".tmp")
        os.replace(asset_db + ".tmp", asset_db)
        log(f"database: {before} → {after} apps · icons: {icons_before} → {len(os.listdir(asset_icons))}")
        log(f"written {asset_db}")
    finally:
        shutil.rmtree(staging, ignore_errors=True)


if __name__ == "__main__":
    sys.exit(main())
