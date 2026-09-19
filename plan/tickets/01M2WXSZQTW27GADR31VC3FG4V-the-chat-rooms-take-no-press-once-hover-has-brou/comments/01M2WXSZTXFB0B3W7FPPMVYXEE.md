---
revision: 5
id: 01M2WXSZTXFB0B3W7FPPMVYXEE
---

Cause. The catcher sat over the window with SetMouseMotionEnabled(false) and clicks off; the live client still routed the rail's press to it.  Fix. 921a159: the catcher is hidden while the frame is up and shown when the pointer leaves; the recheck ticker lives on the veil, since a hidden frame runs no OnUpdate.  Gate. 88-theme-veil asserts the catcher is hidden once the frame is up.
