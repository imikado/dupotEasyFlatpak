class AppstreamLongEntity:

    def __init__(self, id: str, name: str, summary: str, icon: str,
                 project_license: str, category_id_list: str, description: str,
                 metadata_obj: str, url_obj: str, release_obj_list: str,
                 last_update: int, developer_name: str, screenshot_list: str,
                 last_release_timestamp: int):
        self.id = id
        self.name = name
        self.summary = summary
        self.icon = icon
        self.project_license = project_license
        self.category_id_list = category_id_list
        self.description = description
        self.metadata_obj = metadata_obj
        self.url_obj = url_obj
        self.release_obj_list = release_obj_list
        self.last_update = last_update
        self.developer_name = developer_name
        self.screenshot_list = screenshot_list
        self.last_release_timestamp = last_release_timestamp
