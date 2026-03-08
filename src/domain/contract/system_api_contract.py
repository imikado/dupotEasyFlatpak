from abc import ABC, abstractmethod


class SystemApiContract(ABC):

    @abstractmethod
    def get_datetime_current_timestamp(self) -> int:
        pass
