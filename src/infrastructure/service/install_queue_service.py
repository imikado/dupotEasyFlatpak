from dataclasses import dataclass, field
from typing import Callable, List


@dataclass
class InstallQueueItem:
    app_id: str
    app_name: str
    scope: str = "user"
    status: str = "installing"
    output_lines: List[str] = field(default_factory=list)
    _output_callbacks: List[Callable] = field(default_factory=list)
    _status_callbacks: List[Callable] = field(default_factory=list)

    def subscribe_output(self, cb: Callable):
        self._output_callbacks.append(cb)

    def unsubscribe_output(self, cb: Callable):
        if cb in self._output_callbacks:
            self._output_callbacks.remove(cb)

    def subscribe_status(self, cb: Callable):
        self._status_callbacks.append(cb)

    def unsubscribe_status(self, cb: Callable):
        if cb in self._status_callbacks:
            self._status_callbacks.remove(cb)

    def append_output(self, line: str):
        self.output_lines.append(line)
        for cb in list(self._output_callbacks):
            cb(line)

    def set_status(self, status: str):
        self.status = status
        for cb in list(self._status_callbacks):
            cb(status)


class InstallQueueService:
    _instance = None

    def __new__(cls):
        if cls._instance is None:
            cls._instance = super().__new__(cls)
            cls._instance._items = []
            cls._instance._change_callbacks = []
        return cls._instance

    def enqueue(self, app_id: str, app_name: str, scope: str = "user") -> InstallQueueItem:
        item = InstallQueueItem(app_id=app_id, app_name=app_name, scope=scope)
        self._items.append(item)
        for cb in list(self._change_callbacks):
            cb()
        return item

    def get_all(self) -> List[InstallQueueItem]:
        return list(self._items)

    def subscribe_changes(self, cb: Callable):
        self._change_callbacks.append(cb)

    def unsubscribe_changes(self, cb: Callable):
        if cb in self._change_callbacks:
            self._change_callbacks.remove(cb)
