# Task Breakdown: UX425EA Hardware Enablement

## Task 1: Add UX425EA hardware profile scaffolding

**Status:** Done

**Description:**  
Refactor build flow so UX425EA-specific enablement can be added in focused slices without growing one monolithic script. Introduce clear profile entrypoint and ordered script hooks for graphics, reliability, and power.

**Acceptance criteria:**
- [ ] Build flow has explicit hardware profile section for UX425EA.
- [ ] Script structure allows independent hardware slices without duplicated logic.
- [ ] Existing kernel swap/custom apps behavior remains intact.

**Verification:**
- [ ] `just check`
- [ ] `just lint`
- [ ] `just build localhost/aurora-dx latest`

**Dependencies:** None

**Files likely touched:**
- `build_files/build.sh`
- `build_files/*.sh` (new modular scripts)

**Estimated scope:** M

---

## Task 2: Implement Intel Iris Xe graphics/media slice

**Status:** Done

**Description:**  
Add Intel userspace graphics/media support for Tiger Lake Iris Xe including VA-API and Vulkan toolchain expectations, ensuring default stack comes up correctly after install.

**Acceptance criteria:**
- [ ] Image includes required Intel graphics/media packages and firmware pieces for Iris Xe workflows.
- [ ] VA-API and Vulkan command-line checks are available in image.
- [ ] No manual post-install package installation required for graphics/media support.

**Verification:**
- [ ] `just build localhost/aurora-dx latest`
- [ ] On device: `glxinfo -B`
- [ ] On device: `vulkaninfo --summary`
- [ ] On device: `vainfo`

**Dependencies:** Task 1

**Files likely touched:**
- `build_files/build.sh`
- `build_files/hw-graphics.sh` (new)
- `README.md`

**Estimated scope:** M

---

## Task 3: Implement suspend/resume + external display reliability slice

**Description:**  
Add targeted settings/packages needed for stable suspend/resume and external monitor workflows on UX425EA, avoiding broad risky kernel-level changes unless required.

**Acceptance criteria:**
- [ ] Suspend/resume path includes required support tooling/config in image.
- [ ] External display attach/detach works without manual fixes.
- [ ] No repeated post-resume graphics lockups in normal use checks.

**Verification:**
- [ ] `just build localhost/aurora-dx latest`
- [ ] On device: repeated suspend/resume cycles succeed
- [ ] On device: external monitor hotplug test succeeds

**Dependencies:** Task 2

**Files likely touched:**
- `build_files/build.sh`
- `build_files/hw-reliability.sh` (new)
- `README.md`

**Estimated scope:** M

---

## Task 4: Implement built-in peripheral reliability slice (audio/camera/Wi-Fi/BT)

**Description:**  
Ensure integrated peripherals on UX425EA are enabled and reliable out of box, including required firmware/userspace support and service defaults.

**Acceptance criteria:**
- [ ] Audio, camera, Wi-Fi, and Bluetooth are functional after first boot without manual install/config.
- [ ] Required firmware/userspace packages are explicitly included in build flow.
- [ ] No mandatory post-install service enablement steps for these peripherals.

**Verification:**
- [ ] `just build localhost/aurora-dx latest`
- [ ] On device: `wpctl status` / audio playback test
- [ ] On device: camera test with PipeWire-compatible app
- [ ] On device: Wi-Fi association + Bluetooth pairing check

**Dependencies:** Task 1

**Files likely touched:**
- `build_files/build.sh`
- `build_files/hw-peripherals.sh` (new)
- `README.md`

**Estimated scope:** M

---

## Task 5: Implement balanced perf/power tuning slice

**Description:**  
Apply balanced daily-use performance and power policies for Tiger Lake laptop behavior, favoring stable thermals/battery over aggressive max-performance tuning.

**Acceptance criteria:**
- [ ] Default tuning stack and services are configured for balanced daily use.
- [ ] Idle power target path is measurable and documented (`<= 8W` under defined idle conditions).
- [ ] No thermal instability under sustained mixed CPU+GPU workload checks.

**Verification:**
- [ ] `just build localhost/aurora-dx latest`
- [ ] On device: `powerstat` or `powertop` sampling run recorded
- [ ] On device: sustained mixed workload sanity check

**Dependencies:** Tasks 3, 4

**Files likely touched:**
- `build_files/build.sh`
- `build_files/hw-power.sh` (new)
- `README.md`

**Estimated scope:** M

---

## Task 6: Add validation automation + acceptance runbook

**Description:**  
Create reproducible validation flow that maps SPEC success criteria to concrete build commands and on-device runtime checks, including evidence capture format.

**Acceptance criteria:**
- [ ] Validation checklist maps 1:1 to SPEC success criteria.
- [ ] Build-time verification commands and expected outputs are documented.
- [ ] On-device verification sequence is documented in execution order.

**Verification:**
- [ ] `just check`
- [ ] `just lint`
- [ ] `just build localhost/aurora-dx latest`
- [ ] Manual dry run of documented validation sequence

**Dependencies:** Tasks 2, 3, 4, 5

**Files likely touched:**
- `README.md`
- `SPEC.md`
- `tasks/plan.md`

**Estimated scope:** S
