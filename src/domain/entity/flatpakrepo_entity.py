class FlatpakRepoEntity:

    def __init__(self, row):
        self.id = row["id"]
        self.url = row["url"]
        self.api = row["api"] if row["api"] else ""

    def getId(self) -> str:
        return self.id

    def getUrl(self) -> str:
        return self.url

    def getApi(self) -> str:
        return self.api
