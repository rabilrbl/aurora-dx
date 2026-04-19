# Spec: UX425EA Hardware Enablement (i7-1165G7 + Iris Xe)

## Assumptions I'm Making
1. Scope is one device model only: **Asus Zenbook 14 2020 UX425EA** with **Intel i7-1165G7** and **Iris Xe**.
2. Goal is full out-of-box hardware experience after fresh install, without manual post-install tweaks.
3. We can add packages, repos, scripts, and config files if needed for stable support.
4. Base image remains `ghcr.io/ublue-os/aurora-dx:stable` unless explicitly changed.
5. Target profile is balanced daily-use performance.

## Objective
Deliver image-level improvements that maximize compatibility, graphics/media support, suspend reliability, external display behavior, and power efficiency for UX425EA, while keeping builds reproducible and maintainable in this repo.

Primary user: owner of this specific UX425EA device.

## Tech Stack
- Bootable container image: `bootc`
- Base image: `ghcr.io/ublue-os/aurora-dx:stable`
- Build/runtime customization: `Containerfile` + Bash (`build_files/build.sh`)
- Package manager inside image build: `dnf5`
- Local orchestration and helper commands: `just`
- CI/CD: GitHub Actions (`.github/workflows/build.yml`, `build-disk.yml`)

## Commands
Build image:
```bash
just build localhost/aurora-dx latest
```

Lint shell scripts:
```bash
just lint
```

Check Justfile syntax:
```bash
just check
```

Format shell scripts / fix Justfiles:
```bash
just format && just fix
```

## Project Structure
- `Containerfile` → image entrypoint and build stages
- `build_files/build.sh` → main package/config/customization logic
- `disk_config/*.toml` → bootc image-builder disk/ISO config
- `.github/workflows/build.yml` → container image CI publish/sign flow
- `.github/workflows/build-disk.yml` → disk image CI flow
- `Justfile` → local build/lint/VM recipes
- `cosign.pub` → image signing public key

## Code Style
Shell-first, strict mode, explicit failure behavior, no silent fallback for critical paths.

```bash
#!/bin/bash
set -ouex pipefail

case "$(uname -m)" in
  x86_64) ZEN_ARCH="x86_64" ;;
  aarch64 | arm64) ZEN_ARCH="aarch64" ;;
  *)
    echo "Unsupported architecture" >&2
    exit 1
    ;;
esac
```

Conventions:
- Keep logic deterministic and idempotent where possible.
- Use explicit `exit 1` on unsupported/invalid states.
- Keep hardware-specific changes grouped and clearly named.

## Testing Strategy
No unit-test framework exists in this repo; validation is build + runtime verification.

1. Static checks:
   - `just check`
   - `just lint`
2. Build checks:
   - `just build localhost/aurora-dx latest`
   - `just build-qcow2 localhost/aurora-dx latest`
3. Runtime checks on target UX425EA hardware (required):
   - Graphics renderer uses Iris Xe stack (`glxinfo -B` / `vulkaninfo --summary`)
   - VA-API codec paths available (`vainfo`)
   - Suspend/resume reliability over repeated cycles
   - External display attach/detach and stable output
   - Audio, camera, Wi-Fi, Bluetooth functional without manual fixes
4. Perf/power balanced targets (measurable):
   - Idle battery power average at desktop workload: **<= 8W** (`powerstat` or `powertop` over stable sample window)
   - 1080p60 hardware-decoded playback with no persistent frame-drop pattern
   - No critical thermal throttling or hangs during sustained mixed CPU+GPU usage

## Boundaries
- Always:
  - Keep changes reproducible in repo-managed build logic (`Containerfile`, `build_files/*`, `disk_config/*`).
  - Prefer upstream kernel/mesa/firmware paths and document added repos/packages.
  - Keep security-sensitive defaults intact unless explicitly approved.
- Ask first:
  - Base image stream changes (e.g., `stable` -> `latest` or non-Aurora base).
  - Permanent security posture reductions (e.g., broad hardening disablement).
  - New long-lived background services enabled by default.
- Never:
  - Commit secrets/keys.
  - Add manual post-install requirement as mandatory step for core hardware functionality.
  - Bypass CI signing flow for published images.

## Success Criteria
1. UX425EA boots and runs image with all core built-in hardware functional out of box.
2. Iris Xe graphics/media acceleration paths are active and stable.
3. Suspend/resume and external display workflows are reliable in daily use.
4. Balanced perf/power targets are met and documented with command output evidence.
5. All required changes live in tracked repo files and pass existing build/lint workflow.

## Open Questions
- None blocking for spec phase.
