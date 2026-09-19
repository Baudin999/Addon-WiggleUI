---
revision: 5
id: 01M2X6BEXP0TQG1V1BFDFAT4PE
---

Landed in bd2c9e8. ns.db is the worn profile table; a metatable routes every non-Restorable key to WarriorKitDB, so no feature changed. First load moves flat settings into 'Shared' and each character copies it as 'Name - Realm'. Checked against a copy of the live account file: 304 settings moved, 0 left flat, theme/palette unchanged, export 996 chars. Not yet seen in the client: the paste box, and UnitName/GetRealmName at ADDON_LOADED (AceDB relies on both, so expected fine). Gate: 0/0, harness 54-profiles.
