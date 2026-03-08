from genericpath import exists
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
