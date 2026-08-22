class LocalAppEntity:

    FIELD_ID = "id"
    FIELD_NAME = "name"
    FIELD_URL= "url"
    FIELD_VERSION="version"

    id: str
    name: str
    url: str
    version: str
   
    def __init__(self, raw_obj: object):
        self.id = raw_obj[self.FIELD_ID]
        self.name = raw_obj[self.FIELD_NAME]
        self.url = raw_obj[self.FIELD_URL]
        self.version = raw_obj[self.FIELD_VERSION]

    def to_dict(self) -> dict:
        return {self.FIELD_ID: self.id, self.FIELD_NAME: self.name, self.FIELD_URL:self.url,self.FIELD_VERSION:self.version}

 