import json

class ApiCacheEntity:

    def __init__(self, id: str, content: str):
        self.id = id
        self.content = content

    def get_app_id_list(self)->list:
        return json.loads(self.content)
        pass
