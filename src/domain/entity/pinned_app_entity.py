class PinnedAppEntity:

    FIELD_ID = "id"
    FIELD_COMMIT = "commit"

    id: str
    commit: str
   
    def __init__(self, raw_obj: object):
        self.id = raw_obj[self.FIELD_ID]
        self.commit = raw_obj[self.FIELD_COMMIT]

    def to_dict(self) -> dict:
        return {self.FIELD_ID: self.id, self.FIELD_COMMIT: self.commit}

 