---
revision: 5
id: 01M2HWGHJ851XQZNTE7F5NQFE9
---

Cause. The heading: a board was 172 px, and the tree name had only a LEFT anchor, so Beast Mastery and Marksmanship ran under their points. The hover: a talent's description is spell text the client fetches on first ask. The first hover scanned before it landed, Read.TipArgs cached that miss as false for the session, and nothing rebuilt the box when SPELL_DATA_LOAD_RESULT fired. Tip.Arrived could not help: FETCHED covers items only, and a rebuild reuses the subject whose tab and index were nil.  Fix. GAP 16 to 28 in Board.lua (board 208 px, window 108 px wider); name anchored RIGHT to the points LEFT so a longer locale name clips. Read.TipArgs keeps no shape until one way answers. Board.lua tracks the hovered square and calls its OnEnter again on SPELL_DATA_LOAD_RESULT, which recomputes the arguments.  Gate. 67-talents: the name's second anchor is the points; a talent hovered with no client text draws no description, draws it after the event, and a spell landing after OnLeave opens nothing. Not proven: that the live 2.5.6 client fires SPELL_DATA_LOAD_RESULT for a talent's text. Check in game.
