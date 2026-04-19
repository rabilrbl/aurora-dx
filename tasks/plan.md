# Implementation Plan: UX425EA Hardware Enablement

## Overview
Implement device-targeted enablement for Asus Zenbook 14 UX425EA (Intel i7-1165G7 + Iris Xe) in image build pipeline so graphics/media, suspend/resume, external displays, peripherals, and balanced perf/power work out of box after fresh install.

## Architecture Decisions
- Keep base image on `ghcr.io/ublue-os/aurora-dx:stable`; apply support via repo-managed build customizations only.
- Keep hardware logic modular by splitting monolithic `build_files/build.sh` into focused sourced scripts under `build_files/` (GPU/media, peripherals/suspend, power/perf, validation tooling).
- Validate in two layers: CI/build validation (`just check`, `just lint`, `just build`) + on-device runtime validation commands captured in docs.
- Preserve reproducibility: explicit package installs/config files in repo; no mandatory manual post-install steps.

## Dependency Graph
```text
Base image + kernel swap + firmware compatibility
            │
            ├── Intel GPU/media userspace + VA/Vulkan tooling
            │          │
            │          ├── External display behavior + suspend/resume stability
            │          │          │
            │          │          └── Peripheral reliability (audio/camera/Wi-Fi/BT)
            │          │
            │          └── Balanced power/perf policy tuning
            │
            └── Validation scripts + docs + CI verification flow
```

## Task List

### Phase 1: Foundation + Graphics Path
- [x] Task 1: Introduce UX425EA hardware profile scaffolding in build flow.
- [x] Task 2: Implement Intel Iris Xe graphics/media package and config slice.

### Checkpoint: After Phase 1
- [ ] `just check` passes
- [ ] `just lint` passes
- [ ] `just build localhost/aurora-dx latest` succeeds
- [ ] Image contains intended Intel graphics/media packages

### Phase 2: Reliability Slices
- [ ] Task 3: Implement suspend/resume + external display reliability slice.
- [ ] Task 4: Implement built-in peripheral reliability slice (audio/camera/Wi-Fi/BT).

### Checkpoint: After Phase 2
- [ ] Build + lint still pass
- [ ] Runtime verification list updated for display/suspend/peripherals
- [ ] No manual post-install steps required for core hardware path

### Phase 3: Balanced Perf/Power + Validation
- [ ] Task 5: Implement balanced power/performance tuning slice with measurable targets.
- [ ] Task 6: Add validation automation and operator documentation for acceptance criteria evidence.

### Checkpoint: Complete
- [ ] All SPEC success criteria mapped to concrete verification steps
- [ ] Build pipeline remains reproducible
- [ ] Plan/todo accepted before implementation starts

## Risks and Mitigations
| Risk | Impact | Mitigation |
|---|---|---|
| Kernel choice interacts badly with Tiger Lake power states | High | Keep tuning incremental; validate suspend/power after each slice; avoid broad kernel arg changes initially |
| GPU/media package conflicts across repos | High | Pin to Fedora-compatible Intel stack first; add one repo source at a time; validate VA/Vulkan immediately |
| Over-tuning power settings hurts performance or stability | Medium | Use balanced defaults; keep aggressive knobs opt-in, not default |
| CI cannot fully assert hardware behavior | Medium | Add clear on-device validation runbook + command evidence capture |

## Open Questions
- Whether to keep all enablement always-on for all x86_64 installs, or gate by DMI/device detection in build/runtime scripts.
- Whether balanced power target should be validated using `powerstat`, `powertop`, or both as canonical evidence source.
