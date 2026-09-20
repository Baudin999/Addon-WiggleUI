---
revision: 5
id: 01M2Z4V2QSFYQ5Y4GZ9FEA67AH
---

Reopened: the fix on this card was backwards and d969dd1c takes it out.

Cause. 30958cfa read a vertical Slider on this client as having its minimum at the bottom of the track and mirrored every read and write of a scroll bar around its span. The reading is wrong, and this is the third time this card has been decided by reasoning rather than by a witness, so here are three. Slider:SetOrientation is documented as VERTICAL moving the thumb from the top of the track to the bottom as the value rises. Blizzard's HybridScrollFrame hands its bar's value straight to HybridScrollFrame_SetOffset as the offset from the top of the list and disables the down button at the maximum. AceGUI's scroll container and LibQTip both feed a vertical slider's value in positive on this install, and no scrollbar on this install mirrors one. The card body had this right before the mirror went in; the comment above, which says it was confirmed in the game, was not.

What the mirror cost is both ends of one bar. Under the wheel the page moved correctly and the thumb beside it climbed as the page went down, which is what got reported as an inverted wheel. Under a drag the page moved against the hand, which is the inversion this card was opened about, so the card's own symptom was never fixed.

Fix. d969dd1c. UI.ScrollSpan and UI.ScrollAt stay and do no arithmetic: the offset is the slider's value. The guard in each stays, which is the part of 30958cfa worth keeping. 02-scroll-bar.lua keeps its shape and turns round, and fails the same four lines if the mirror comes back. 29-social goes back to counting the slider stub's writes, because the range check only existed to see round the mirror.

Still open, and it is one answer from the game. With the mirror gone the bar is back to what it was when this was first reported: value counted from the top, written straight on the widget. If the drag still runs backwards in the quest window then it is not the slider's polarity and nothing in UI/Scroll.lua explains it, because the wheel and the drag both end up in View:ScrollTo with the same number. What is needed is which column, and whether pulling the thumb down moves the page up or leaves the page alone and throws the thumb back. The second is a write-back fight during the drag, which View:ScrollTo can cause and the wheel cannot.
