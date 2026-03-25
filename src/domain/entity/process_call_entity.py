class ProcessCallEntity:

    arg_list: list[str] = []

    def __init__(self, arg_list: list[str]):
        self.arg_list = arg_list
        pass

    def add_arg(self, arg: str):
        self.arg_list.append(arg)

    def get_arg_list(self) -> list[str]:
        return self.arg_list
