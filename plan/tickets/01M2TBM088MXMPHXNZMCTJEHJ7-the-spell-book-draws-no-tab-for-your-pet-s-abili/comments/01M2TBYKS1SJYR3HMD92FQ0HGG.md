---
revision: 5
id: 01M2TBYKS1SJYR3HMD92FQ0HGG
---

Reopened: live client showed no pet tab. Cause: Entry kept only kind == SPELL, and 2.5.6 does not answer SPELL for pet abilities; the fixture claimed it did. Fix in 643f644: pet entries are read by select(7, GetSpellInfo(index, 'pet')), the call OPie makes on this client; no id means a command. Fixture now answers PETACTION for every pet entry. Unverified in game at commit time.
