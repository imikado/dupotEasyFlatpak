from datetime import datetime


class ReleaseEntity:

    version: str
    datetime: str

    def __init__(self, timestamp: str, version: str):
        self.version = version

        release_datetime = datetime.fromtimestamp(int(timestamp))

        self.datetime = release_datetime.strftime("%d/%m/%Y")
