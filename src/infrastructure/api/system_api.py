from genericpath import exists
import json
import shutil
import subprocess
import tempfile
import os
import time
import zipfile

from domain.contract.system_api_contract import SystemApiContract


class SystemApi(SystemApiContract):

    _password: str

    def read_file(self, path: str):
        return open(path, "r").read()

    def write_file(self, path: str, content: str):
        open(path, "w").write(content)

    def write_file_tmp(self, content: str) -> str:
        with tempfile.NamedTemporaryFile(mode="w", delete=False, suffix=".nix") as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        return tmp_path

    def remove_file(self, path: str):
        os.remove(path)

    def remove_directory(self, path: str):
        shutil.rmtree(path)

    def execute(self, params: list):
        subprocess.Popen(params)

    def file_exists(self, path: str) -> bool:
        return exists(path)

    def create_dir(self, path: str):
        os.mkdir(
            path,
            mode=0o777,
        )

    def copy_file(self, path_from: str, path_to: str):
        shutil.copy(path_from, path_to)

    def get_datetime_current_timestamp(self) -> int:
        return int(time.time() * 1000)

    def unzip_archive_to(self, archive_path: str, path_to: str):
        with zipfile.ZipFile(archive_path, "r") as zip_ref:
            zip_ref.extractall(path_to)

    def read_json_file_obj(self, path: str) -> object:
        return self._load_json_file(path)

    def read_json_file_str_list(self, path: str) -> list[str]:
        return self._load_json_file(path)

    def read_json_file_obj_list(self, path: str) -> list[object]:
        return self._load_json_file(path)

    def _load_json_file(self, path: str) -> any:
        with open(path, "r") as file:
            return json.load(file)

    def download_remote_file_to(self, remote_path: str, local_path: str):
        import urllib.request
        urllib.request.urlretrieve(remote_path, local_path)
