# bg3-tk-mod-repo-template


Git repo template for bg3 toolkit mod projects


## Required Dependencies
- Python runtime
  - https://www.python.org/downloads/
- Git
  - https://git-scm.com/downloads
  - There are other clients as well, I use https://desktop.github.com/download/
- Junctions
  - https://learn.microsoft.com/en-us/sysinternals/downloads/junction
  - This is not an installer, but an executable.  Either place somewhere that is in your path
    or make a note of the path to where this is kept


## Usage
1. Create a project in the Baldur's Gate 3 Toolkit
2. [Create a new repository from the template](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-repository-from-a-template)
3. Clone the new repo to a non-protected directory (not in something like Program Files)
4. Update properties at the top of `repo-setup.py` and save
5. Run `python repo-setup.py` from command prompt, or double-click on script
6. Going forward you should be able to commit/push/pull/etc. like any other git repo
