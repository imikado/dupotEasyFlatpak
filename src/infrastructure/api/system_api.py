from genericpath import exists
import subprocess
import tempfile
import os
import datetime

from domain.contract.system_api_contract import SystemApiContract


class SystemApi(SystemApiContract):

    _password:str

    def read_file(self, path: str):
        return open(path, 'r').read()

    def write_file(self, path: str, content: str):
        open(path, 'w').write(content)

    def backup_file_sudo(self,path:str,password:str):
        self._password=password


        datetime_now = datetime.datetime.now()

        backup_file_path=path+'.nix-samba.back'+datetime_now.strftime('%Y%m%d')

        self.sudo_execute(['sudo','-S','cp',path,backup_file_path])

    def write_file_tmp(self, content: str)->str:
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.nix') as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        return tmp_path

    def write_file_sudo(self, path: str, content: str, password: str):

        self._password=password
        
        """Write file with elevated privileges using sudo."""
        # Write content to a temporary file first
        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.nix') as tmp:
            tmp.write(content)
            tmp_path = tmp.name

        try:
            if False==exists(path):

                self.sudo_execute(['sudo', '-S', 'touch', path])
                self.sudo_execute(['sudo', '-S', 'chmod','644', path])

                
            self.sudo_execute(['sudo', '-S', 'cp', tmp_path, path])
        finally:
            # Clean up temp file
            os.unlink(tmp_path)

    def execute(self,params:list):
        subprocess.Popen(params)
    
    def sudo_execute(self,params:list):
        process = subprocess.Popen(
                params,
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
        stdout, stderr = process.communicate(input=f"{self._password}\n")

        if process.returncode != 0:
            if "incorrect password" in stderr.lower() or "sorry" in stderr.lower():
                raise PermissionError("Incorrect password")
            raise PermissionError(f"Failed to excute commands: {stderr}")

    def file_exists(self,path:str)->bool:
        return exists(path)
    
    def create_dir(self,path:str):
        os.mkdir(path, mode=0o777,)

    def nix_rebuild_sudo(self,password:str):
        self._password=password
        self.sudo_execute(['sudo', '-S', 'nixos-rebuild','switch'])
        pass

    def chown_smb_creds_file(self,path:str):
        subprocess.Popen(['chmod','600',path])

    def get_gtk_bookmark_list(self)->list:
        bookmarks_path = os.path.join(os.path.expanduser('~'), '.config', 'gtk-3.0', 'bookmarks')
        if not os.path.isfile(bookmarks_path):
            return []
        with open(bookmarks_path, 'r') as f:
            return [line.rstrip('\n') for line in f if line.strip()]

    def write_gtk_bookmark_list(self,bookmark_list:list):
        bookmarks_path = os.path.join(os.path.expanduser('~'), '.config', 'gtk-3.0', 'bookmarks')
        current_list = self.get_gtk_bookmark_list()
        if current_list == bookmark_list:
            return
        os.makedirs(os.path.dirname(bookmarks_path), exist_ok=True)
        with open(bookmarks_path, 'w') as f:
            for bookmark in bookmark_list:
                f.write(bookmark + '\n')

    def write_rebuild_bash(self,tmp_samba_nix_path:str):

        rebuld_bash_content="""#!/usr/bin/env bash
echo "======================================"
echo "  save samba.nix"
echo "======================================"
echo ""

sudo mv """+tmp_samba_nix_path+""" /etc/nixos/customConfig/samba.nix
        

echo "======================================"
echo "  NIX REBUILD with samba setup"
echo "======================================"
echo ""


echo "nixos-rebuild..."
echo ""

# Detect flake configuration name for --flake flag
FLAKE_ATTR=""
if [ -f /etc/nixos/flake.nix ]; then
    FLAKE_ATTR=$(grep -oP 'nixosConfigurations\\.\\s*"?\\K[^"= ]+' /etc/nixos/flake.nix | head -1)
fi

if [ -n "$FLAKE_ATTR" ]; then
    echo "Configuration flake detectee : $FLAKE_ATTR"
    sudo nixos-rebuild switch --flake "/etc/nixos#$FLAKE_ATTR"
else
    sudo nixos-rebuild switch
fi
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
    echo ""
    echo "======================================"
    echo "  REBUILD successfully"
    echo "======================================"
else
    echo ""
    echo "======================================"
    echo "  Error during REBUILD"
    echo "======================================"
fi

echo ""
echo "You can close this terminal window."
"""

        with tempfile.NamedTemporaryFile(mode='w', delete=False, suffix='.sh') as tmp:
                tmp.write(rebuld_bash_content)
                self.execute(['chmod','+x',tmp.name])
                return tmp.name