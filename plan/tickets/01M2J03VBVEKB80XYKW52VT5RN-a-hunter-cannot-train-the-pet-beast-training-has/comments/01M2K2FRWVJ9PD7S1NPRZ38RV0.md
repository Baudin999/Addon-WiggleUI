---
revision: 5
id: 01M2K2FRWVJ9PD7S1NPRZ38RV0
---

Reported in game on 37760b6: clicking Growl rank 4 still teaches nothing and shows nothing.  No fix this time. Three fixes written by reading the code have failed, so 46f5d58 adds /wk talents trace (Talents/Trace.lua). It prints the hover (armed or why not, with the page's level and points reading), a click the row took instead of the secure button, selection and create button before and after PreClick, whether CraftCreateButton ran its OnClick, and BLOCKED, FORBIDDEN, UI_ERROR_MESSAGE and CRAFT_UPDATE.  Next. The user reloads, runs the trace, hovers and clicks Growl rank 4, and pastes the pet lines. The last line that prints says which link breaks.  Gate. 67-pet-training requires the four trace lines; hook green.
