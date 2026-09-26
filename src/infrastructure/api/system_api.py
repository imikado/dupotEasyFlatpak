from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
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

    def write_json_file(self, path: str, data: any):
        with open(path, "w") as f:
            json.dump(data, f, indent=2)

    def write_binary_file(self, path: str, data: bytes):
        with open(path, "wb") as f:
            f.write(data)

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
        if os.path.exists(path_to):
            os.chmod(path_to, 0o600)
        shutil.copyfile(path_from, path_to)
        os.chmod(path_to, 0o600)

    def copy_dir(self, path_from: str, path_to: str):
        destination = (
            os.path.join(path_to, os.path.basename(os.path.normpath(path_from)))
            if os.path.isdir(path_to)
            else path_to
        )
        if os.path.exists(destination):
            self.make_tree_writable(destination)

        # Thousands of small files (e.g. app icons) is slow to copy one at
        # a time. Skip files that are already there and the same size (the
        # common case on every launch after the first — most icons never
        # change between versions) and run the actual copies concurrently
        # — I/O-bound, so threads genuinely parallelize this despite the GIL.
        copy_tasks = []
        with ThreadPoolExecutor(max_workers=8) as executor:
            for root, _dirs, files in os.walk(path_from):
                rel_dir = os.path.relpath(root, path_from)
                dst_dir = destination if rel_dir == "." else os.path.join(destination, rel_dir)
                os.makedirs(dst_dir, exist_ok=True)
                for file_name in files:
                    src_path = os.path.join(root, file_name)
                    dst_path = os.path.join(dst_dir, file_name)
                    copy_tasks.append(
                        executor.submit(self._copy_file_if_changed, src_path, dst_path)
                    )
            for task in copy_tasks:
                task.result()

        self.make_tree_writable(destination)

    @staticmethod
    def _copy_file_if_changed(src_path: str, dst_path: str):
        try:
            if os.path.getsize(dst_path) == os.path.getsize(src_path):
                return
        except OSError:
            pass  # dst doesn't exist (or is unreadable) — copy it
        shutil.copyfile(src_path, dst_path)

    def make_tree_writable(self, path: str):
        """Repair runtime data copied from a read-only package store."""
        if not os.path.exists(path):
            return
        if os.path.isfile(path):
            os.chmod(path, 0o600)
            return
        os.chmod(path, 0o700)
        for root, directories, files in os.walk(path):
            for directory in directories:
                os.chmod(os.path.join(root, directory), 0o700)
            for file_name in files:
                os.chmod(os.path.join(root, file_name), 0o600)
 
    def get_datetime_current_timestamp(self) -> int:
        return int(time.time())

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

    def download_remote_file_to(self, remote_path: str, local_path: str) -> bool:
        import urllib.request
        import urllib.error

        if not remote_path:
            return False
        try:
            urllib.request.urlretrieve(remote_path, local_path)
            return True
        except (urllib.error.URLError, urllib.error.HTTPError, TypeError):
            return False

    def get_current_datetime_string(self) -> str:
        now = datetime.now()
        return now.strftime("%Y-%m-%d")

    def get_file_list(self, path: str) -> list[str]:
        files = os.listdir(path)
        return [file.lower() for file in files]
