---
name: zeph-mute
description: >
  Mute Zeph push notifications for this session. Stops automatic notifications
  from Stop and AskUserQuestion hooks. Use /zeph-unmute to re-enable.
metadata:
  author: zeph-to
  version: "0.4.0"
---

Mute Zeph notifications for this session.

Run this bash command:

```bash
HASH=$(echo -n "${CLAUDE_PROJECT_DIR:-$(pwd)}" | cksum | cut -d' ' -f1)
touch "/tmp/zeph-muted-$HASH"
```

Respond: "Zeph notifications muted for this session. Use /zeph-unmute to re-enable."
