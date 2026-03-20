class FlatpakHistoryEntity:

    commit: str
    subject: str
    date: str

    def __init__(self, commit: str, subject: str, date: str):
        self.commit = commit
        self.subject = subject
        self.date = date
        pass
