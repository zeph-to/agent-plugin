---
name: zeph-unmute
description: >
  Unmute Zeph push notifications for this session. Re-enables automatic
  notifications from Stop and AskUserQuestion hooks.
---

Unmute Zeph notifications for this session.

Run this bash command:

```bash
HASH=$(echo -n "${CLAUDE_PROJECT_DIR:-$(pwd)}" | cksum | cut -d' ' -f1)
rm -f "/tmp/zeph-muted-$HASH"
```

Respond: "Zeph notifications re-enabled for this session."
