# CHANGELOG.md

## 1.0.0

=== Script Extender
-- Backend
Charvis and head materials are now patched at runtime instead of being overriden in files
Companions are now fully supported, this includes compatibility with Padme's UAC mod ensuring they keep her materials
Due to the above, mods like EotB or body altering mods will work out of the box
STAV CC elements handled by the UI panel should display correctly in every cutscene
Code has been optimized and should be more performant
--UI
Added themes and shareable presets
Advanced settings moved from the MCM tab to its own tab in the UI panel
Added two buttons next to the sliders for easier use
=== Internals
Charvis lsf overrides have been removed
Fixed BodyScars colouring
Added Karlach's pulsing heartbeat
Ensured default materials are set correctly
Restored gith spots as a non tattoo slot
Gave companions their own VTs allowing full body customization
Virtual textures have been split into their own pak for easier updating and not forcing users to redownload a 1GB file every time