class PermissionToOverrideEntity:

    FIELD_LABEL = "label"
    FIELD_TYPE = "type"
    FIELD_VALUE = "value"

    label: str
    type: str
    value: str

    def __init__(self, raw_obj: object):

        if self.FIELD_LABEL in raw_obj:
            self.label = raw_obj[self.FIELD_LABEL]
        if self.FIELD_TYPE in raw_obj:
            self.type = raw_obj[self.FIELD_TYPE]
        if self.FIELD_VALUE in raw_obj:
            self.value = raw_obj[self.FIELD_VALUE]

        pass


# {
#    "label": "recipe_share_your_home_label",
#    "type": "filesystem_noprompt",
#    "value": "home",
# }
