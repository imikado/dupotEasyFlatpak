from abc import abstractmethod


class UserSettingsApiContract:

    @abstractmethod
    def save(self):
        pass

    pass
