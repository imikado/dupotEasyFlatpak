from domain.entity.permission_to_override_entity import PermissionToOverrideEntity


class RecipeEntity:

    FIELD_PERMISSION_TO_OVERRIDE_LIST = "flatpakPermissionToOverrideList"

    title: str
    description: str
    flatpak: str
    _flatpak_permission_to_override_list: list[PermissionToOverrideEntity]

    def __init__(self, raw_obj: object):

        self.title = raw_obj["title"]
        self.description = raw_obj["description"]
        self.flatpak = raw_obj["flatpak"]

        self._flatpak_permission_to_override_list = []
        if self.FIELD_PERMISSION_TO_OVERRIDE_LIST in raw_obj:
            for permission_to_override_loop in raw_obj[
                self.FIELD_PERMISSION_TO_OVERRIDE_LIST
            ]:
                self._flatpak_permission_to_override_list.append(
                    PermissionToOverrideEntity(permission_to_override_loop)
                )

    def get_permission_to_override_list(self) -> list[PermissionToOverrideEntity]:
        return self._flatpak_permission_to_override_list
