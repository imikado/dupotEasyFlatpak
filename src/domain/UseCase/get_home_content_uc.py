from domain.entity.application_entity import ApplicationEntity


class GetHomeContentUC:

    def get_trending_list(self):

        trending_list=[]

        trending_list.append(ApplicationEntity('org.dupot.easyflatpak.png','Easy flatpak','org.dupot.easyflatpak.png','Manage your flatpaks with a simple GUI.'))
        trending_list.append(ApplicationEntity('org.dupot.beatmatchtopass.png','Beat match to pass','org.dupot.beatmatchtopass.png','Beat them all'))
        trending_list.append(ApplicationEntity('org.dupot.littleadventure.png','Little adventure','org.dupot.littleadventure.png','RPG Pixel Art little Game'))
        trending_list.append(ApplicationEntity('org.dupot.savethesheep.png','Save the sheep','org.dupot.savethesheep.png','Protect the sheep on each level'))


        return trending_list
