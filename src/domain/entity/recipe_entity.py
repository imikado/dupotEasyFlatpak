from domain.entity.permission_override_entity import PermissionOverrideEntity


class RecipeEntity:

    FIELD_PERMISSION_TO_OVERRIDE_LIST = "flatpakPermissionToOverrideList"

    title: str
    description: str
    flatpak: str
    _flatpak_permission_to_override_list: list[PermissionOverrideEntity]
    _hidden: bool = False

    def __init__(self, raw_obj: object):

        self.title = raw_obj["title"]
        self.description = raw_obj["description"]
        self.flatpak = raw_obj["flatpak"]

        if "hidden" in raw_obj:
            self._hidden = True

        self._flatpak_permission_to_override_list = []
        if self.FIELD_PERMISSION_TO_OVERRIDE_LIST in raw_obj:
            for permission_to_override_loop in raw_obj[
                self.FIELD_PERMISSION_TO_OVERRIDE_LIST
            ]:
                self._flatpak_permission_to_override_list.append(
                    PermissionOverrideEntity(permission_to_override_loop)
                )

    def get_permission_to_override_list(self) -> list[PermissionOverrideEntity]:
        return self._flatpak_permission_to_override_list

    def is_hidden(self) -> bool:
        return self._hidden
