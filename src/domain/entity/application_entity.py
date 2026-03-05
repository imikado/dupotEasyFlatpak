class ApplicationEntity:

    def __init__(self,id,name,icon,summary):
        self.id=id
        self.name=name
        self.icon=icon
        self.summary=summary
        pass

    def getName(self)->str:
        return self.name
    
    def getSummary(self)->str:
        return self.summary
    

    def getIcon(self)->str:
        return '~/.data/Icons/{self.icon}'

    pass