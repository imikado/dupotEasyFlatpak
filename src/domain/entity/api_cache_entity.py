import json


class ApiCacheEntity:

    FIELD_LAST_HOME_API_SYNC_TIMESTAMP = "lastHomeApiSyncTimeStamp"
    FIELD_LAST_API_SYNC_TIMESTAMP = "lastApiSyncTimeStamp"
    FIELD_LAST_API_LANG="lastApiLang"

    def __init__(self, id: str, content: str):
        self.id = id
        self.content = content

    def get_app_id_list(self) -> list:
        return json.loads(self.content)

    def get_home_api_updated_timestamp(self) -> int:
        parameters_obj = json.loads(self.content)
        if self.FIELD_LAST_HOME_API_SYNC_TIMESTAMP not in parameters_obj:
            return 0
        return parameters_obj[self.FIELD_LAST_HOME_API_SYNC_TIMESTAMP]

    def update_home_api_updated_timestamp(self, timestamp: int) -> object:
        parameters_obj = json.loads(self.content)
        parameters_obj[self.FIELD_LAST_HOME_API_SYNC_TIMESTAMP] = timestamp

        self.content = json.dumps(parameters_obj)

        return parameters_obj

    def get_api_last_sync_timestamp(self) -> int:
        parameters_obj = self.get_content_as_object()
        if self.FIELD_LAST_API_SYNC_TIMESTAMP not in parameters_obj:
            return 0
        return parameters_obj[self.FIELD_LAST_API_SYNC_TIMESTAMP]

    def get_api_last_lang(self)->str:
        parameters_obj = self.get_content_as_object()
        if self.FIELD_LAST_API_LANG not in parameters_obj:
            return 'no'
        return parameters_obj[self.FIELD_LAST_API_LANG]

    def update_api_last_sync_timestamp(self, timestamp: int, lang:str) -> object:
        parameters_obj = json.loads(self.content)
        parameters_obj[self.FIELD_LAST_API_SYNC_TIMESTAMP] = timestamp
        parameters_obj[self.FIELD_LAST_API_LANG]=lang

        self.content = json.dumps(parameters_obj)

        return parameters_obj

    def get_content_as_object(self) -> object:
        return json.loads(self.content)
