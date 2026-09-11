# Dell OptiPlex — dedicated Forge compute node

The OptiPlex is treated as an always-on compute worker, not as a device that should be artificially pinned at 100% CPU. The scheduler should consume available capacity while thermal and power safeguards remain enabled.

## Linux profile

Run locally as root only after confirming this is the intended Forge worker:

```bash
set -eux
systemctl mask sleep.target suspend.target hibernate.target hybrid-sleep.target
if command -v cpupower >/dev/null 2>&1; then cpupower frequency-set -g performance || true; fi
systemctl enable --now ssh || true
mkdir -p /etc/systemd/system/forge-worker.service.d
cat >/etc/systemd/system/forge-worker.service.d/override.conf <<'EOF'
[Service]
Nice=-5
IOSchedulingClass=best-effort
IOSchedulingPriority=0
Restart=always
RestartSec=5
EOF
systemctl daemon-reload
```

Do not disable thermal protection, hardware safety controls, or the OS watchdog. The phrase `100% on` means maximum available compute scheduling with safe thermal/power controls, not forcing a constant 100% CPU load.

## Validation

```bash
systemctl is-enabled sleep.target suspend.target hibernate.target hybrid-sleep.target
uptime
nproc
```

The worker should then be attached to the Forge scheduler using its node identity and resource limits rather than hard-coded assumptions about CPU count.
