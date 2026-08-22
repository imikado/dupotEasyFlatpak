class RemoteFlatpakAppEntity:

    def __init__(self, id,name,version):
        self.id = id
        self.name=name
        self.version = version

    def getId(self) -> str:
        return self.id

    def getName(self)->str:
        return self.name

    def getVersion(self) -> str:
        return self.version

