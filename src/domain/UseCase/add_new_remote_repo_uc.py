from domain.contract.flatpak_api_contract import FlatpakApiContract
from domain.contract.flatpakrepo_repository_contract import FlatpakRepoRepositoryContract
from domain.entity.flatpakrepo_entity import FlatpakRepoEntity


class AddNewRemoteRepoUc:

    _flatpak_api: FlatpakApiContract
    _flatpakrepo_repository: FlatpakRepoRepositoryContract

    _flatpakrepo_in_db_list:list[FlatpakRepoEntity]
    _flatpakrepo_setuped_list:list[FlatpakRepoEntity]

    def __init__(self,flatpak_api:FlatpakApiContract,flatpakrepo_repository:FlatpakRepoRepositoryContract):
        self._flatpak_api=flatpak_api
        self._flatpakrepo_repository=flatpakrepo_repository
        self.load()

    def load(self):
        self._flatpakrepo_in_db_list:list[FlatpakRepoEntity]=self._flatpakrepo_repository.get_all_entities()
        self._flatpakrepo_setuped_list:list[FlatpakRepoEntity]=self._flatpak_api.get_remote_repo_list()

    def add(self,name:str,url:str,scope:str="--user")->tuple[bool,str]:
        if self.already_in_db(name,url):
            return False, "A repository with this name or URL already exists"

        if self.already_setuped_in_flatpak(name,url):
            # Already added to flatpak itself (outside this app) — just track it in our DB.
            flatpakrepo_setuped_found:FlatpakRepoEntity=self.get_flatpakrepo_setuped_by(name,url)
            self._flatpakrepo_repository.insert_repo_id(
                flatpakrepo_setuped_found.getId(), flatpakrepo_setuped_found.getUrl(), ""
            )
            self.load()
            return True, ""

        success, error_message = self._flatpak_api.add_remote(name,url,scope)
        if success:
            self._flatpakrepo_repository.insert_repo_id(name,url,"")
            self.load()

        return success, error_message

    def sync(self):
        for flatpakrepo_setuped_loop in self._flatpakrepo_setuped_list:
            if not self.already_in_db(flatpakrepo_setuped_loop.getId(),flatpakrepo_setuped_loop.getUrl()):
                self._flatpakrepo_repository.insert_repo_id(
                    flatpakrepo_setuped_loop.getId(),flatpakrepo_setuped_loop.getUrl(),""
                )

    def get_flatpakrepo_setuped_by(self,name:str,url:str)->FlatpakRepoEntity:
        for flatpakrepo_setuped_loop in self._flatpakrepo_setuped_list:
            if flatpakrepo_setuped_loop.getId()==name or flatpakrepo_setuped_loop.getUrl()==url:
                 return flatpakrepo_setuped_loop

        raise Exception("Error when try to get_flatpakrepo_setuped_by")

    def already_in_db(self,name,url)->bool:
        for flatpakrepo_in_db_loop in self._flatpakrepo_in_db_list:
            if name == flatpakrepo_in_db_loop.getId() or url == flatpakrepo_in_db_loop.getUrl():
                return True
        return False

    def already_setuped_in_flatpak(self,name,url)->bool:
        for flatpakrepo_setuped_loop in self._flatpakrepo_setuped_list:
            if name == flatpakrepo_setuped_loop.getId() or url == flatpakrepo_setuped_loop.getUrl():
                return True
        return False
