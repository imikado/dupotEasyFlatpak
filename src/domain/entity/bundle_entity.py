class BundleEntity:

    FIELD_ID = "id"
    FIELD_LABEL = "label"
    FIELD_ICON = "icon"
    FIELD_APP_LIST = "applicationList"

    id: str
    label: str
    _icon: str
    _application_list: list[str]

    def __init__(self, raw_obj: object):
        self.id = raw_obj[self.FIELD_ID]
        self.label = raw_obj[self.FIELD_LABEL]

        self._icon = raw_obj[self.FIELD_ICON]
        self._application_list = raw_obj[self.FIELD_APP_LIST]
        pass

    def getIcon(self) -> str:
        return self._icon

    def get_application_list(self) -> list[str]:
        return self._application_list
