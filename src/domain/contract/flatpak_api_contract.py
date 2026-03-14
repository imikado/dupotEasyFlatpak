from abc import abstractmethod


class FlatpakApiContract:

    @abstractmethod
    def get_installed_app_id_list(self) -> list[str]:
        pass
