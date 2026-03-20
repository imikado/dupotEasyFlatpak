from abc import ABC, abstractmethod


class SystemApiContract(ABC):

    @abstractmethod
    def read_file(self, path: str):
        pass

    @abstractmethod
    def write_file(self, path: str, content: str):
        pass

    @abstractmethod
    def get_datetime_current_timestamp(self) -> int:
        pass

    @abstractmethod
    def file_exists(self, path: str) -> bool:
        pass

    @abstractmethod
    def copy_file(self, path_from: str, path_to: str):
        pass

    @abstractmethod
    def remove_file(self, path: str):
        pass

    @abstractmethod
    def remove_directory(self, path: str):
        pass

    @abstractmethod
    def unzip_archive_to(self, archive_path: str, path_to: str):
        pass

    @abstractmethod
    def read_json_file_obj(self, path: str) -> object:
        pass

    @abstractmethod
    def read_json_file_str_list(self, path: str) -> list[str]:
        pass

    @abstractmethod
    def read_json_file_obj_list(self, path: str) -> list[object]:
        pass

    @abstractmethod
    def download_remote_file_to(self, remote_path: str, local_path: str):
        pass
