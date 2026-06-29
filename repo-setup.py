import subprocess
import sys
from pathlib import Path


"""
    These properties should be adjusted before running the script!

    REPO_DIR: If you want to move around the relative path to the actual mod data.  Generally leave as-is
    GAME_DATA_ROOT: Path to your BG3 Data folder
    PATH_TO_JUNCTION_EXE: If junction.exe was added to your PATH variable, leave as-is.  Otherwise path to the exe
    MOD_NAME_FULL: Full project name with UUID, ex. YourModNameHere_857aee99-5f79-fd6e-bf15-8c41e6863b1b
    CREATE_NON_PROJECT_FILES_FOLDER: Creates a directory for toolkit related files like .blend, documents, etc. to store with mod
"""
REPO_DIR: str = "."
GAME_DATA_ROOT: str = "C:\\Program Files (x86)\\Steam\\steamapps\\common\\Baldurs Gate 3\\Data"
PATH_TO_JUNCTION_EXE: str = "junction.exe"
MOD_NAME_FULL: str = "YourModNameHere_857aee99-5f79-fd6e-bf15-8c41e6863b1b"
CREATE_NON_PROJECT_FILES_FOLDER: bool = True


"""
    *** Unless you know what you are doing don't modify below here!! ***
"""
def main():
    # Check that Game path is valid
    game_data_path = Path(GAME_DATA_ROOT)
    if not game_data_path.exists():
        raise RuntimeError(f'Game Data path invalid: [{GAME_DATA_ROOT}]')

    # Check that mod project exists
    if not (game_data_path / 'Mods' / MOD_NAME_FULL).exists():
        raise RuntimeError(f'Mod Project not found: [{MOD_NAME_FULL}]')

    # Set up new dir for mod if not already created
    repo = Path(REPO_DIR)
    mod_subfolder = repo / MOD_NAME_FULL
    if mod_subfolder.exists():
        raise RuntimeError(f'Local Mod Project folder already exists: [{MOD_NAME_FULL}]')
    mod_subfolder.mkdir()

    # Create Sub-directories for project
    (mod_subfolder / "Editor" / "Mods").mkdir(parents=True)
    (mod_subfolder / "Generated" / "Public").mkdir(parents=True)
    (mod_subfolder / "Mods").mkdir()
    (mod_subfolder / "Projects").mkdir()
    (mod_subfolder / "Public").mkdir()

    # Create junctions to project folders
    subprocess.Popen(f'{PATH_TO_JUNCTION_EXE} ./{MOD_NAME_FULL} "{GAME_DATA_ROOT}\\Editor\\Mods\\{MOD_NAME_FULL}"',
                     shell=False, cwd=str(mod_subfolder / "Editor" / "Mods"))
    subprocess.Popen(f'{PATH_TO_JUNCTION_EXE} ./{MOD_NAME_FULL} "{GAME_DATA_ROOT}\\Generated\\Public\\{MOD_NAME_FULL}"',
                     shell=False, cwd=str(mod_subfolder / "Generated" / "Public"))
    subprocess.Popen(f'{PATH_TO_JUNCTION_EXE} ./{MOD_NAME_FULL} "{GAME_DATA_ROOT}\\Mods\\{MOD_NAME_FULL}"',
                     shell=False, cwd=str(mod_subfolder / "Mods"))
    subprocess.Popen(f'{PATH_TO_JUNCTION_EXE} ./{MOD_NAME_FULL} "{GAME_DATA_ROOT}\\Projects\\{MOD_NAME_FULL}"',
                     shell=False, cwd=str(mod_subfolder / "Projects"))
    subprocess.Popen(f'{PATH_TO_JUNCTION_EXE} ./{MOD_NAME_FULL} "{GAME_DATA_ROOT}\\Public\\{MOD_NAME_FULL}"',
                     shell=False, cwd=str(mod_subfolder / "Public"))

    # Add folder for non-project files
    if CREATE_NON_PROJECT_FILES_FOLDER:
        (mod_subfolder / "Non-Project Files").mkdir()


if __name__ == "__main__":
    try:
        main()
    except RuntimeError as error:
        print(error)
        input("Press Enter to exit...")
