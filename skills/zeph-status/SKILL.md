---
name: zeph-status
description: >
  Check Zeph notification status for this session. Shows whether notifications
  are currently muted or active.
---

Check Zeph mute status.

Run this bash command:

```bash
HASH=$(echo -n "$CLAUDE_PROJECT_DIR" | cksum | cut -d' ' -f1)
if [ -f "/tmp/zeph-muted-$HASH" ]; then echo "MUTED"; else echo "ACTIVE"; fi
```

If MUTED: respond "Zeph notifications: MUTED. Use /zeph-unmute to re-enable."
If ACTIVE: respond "Zeph notifications: ACTIVE. Use /zeph-mute to disable."
