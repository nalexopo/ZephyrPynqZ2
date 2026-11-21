# Zephyr patches

Patches against the Zephyr tree (`~/zephyrproject/zephyr`) that this project
needs. These patches are not upstream, so after a fresh `west init` or a
switch to another Zephyr version you have to apply them again.

Base: **Zephyr v4.5.0** (`41d10b59730`).

## 0001: PL310 (L2) outer cache maintenance

`0001-arch-arm-cortex_a_r-add-PL310-outer-cache-maintenance.patch`

**Why:** On the PYNQ-Z2, the FSBL leaves the Zynq-7000 PL310 L2 cache enabled.
Without this patch, Zephyr's data cache maintenance
(`arch/arm/core/cortex_a_r/cache.c`) only covers the Cortex-A9 L1. The GEM
Ethernet DMA reads and writes DDR directly without going through the L2. The
result is that TX frames go out with stale data and RX frames are read from
stale L2 lines.

**What it changes:**

- `soc/xlnx/zynq7000/common/soc.h`: defines `__L2C_PRESENT` and
  `L2C_310_BASE` (`0xF8F02000`), which enables the CMSIS PL310 definitions.
- `soc/xlnx/zynq7000/common/soc.c`: adds an `l2c` entry (4 KiB at
  `L2C_310_BASE`, strongly ordered) to the MMU region table. The existing
  `mpcore` entry only covers `0xF8F00000`–`0xF8F01FFF`. Without the new entry,
  the first L2 register access is a data abort ("2nd Level Translation Fault
  @ 0xf8f02100").
- `arch/arm/core/cortex_a_r/cache.c`: when a PL310 is present and enabled,
  the following functions also operate on the L2:
  - `arch_dcache_flush_range`: L1 clean, then L2 clean.
  - `arch_dcache_invd_range`: L2 invalidate first, then L1, so L1 can't refill
    from stale L2 lines. Partial lines at either end are cleaned+invalidated.
  - `arch_dcache_flush_and_invd_range`: L1, then L2 clean+invalidate.
  - `arch_dcache_flush_all` / `arch_dcache_flush_and_invd_all`: L2 by way.
  - `arch_dcache_invd_all` stays L1 only, because invalidating the whole L2
    would throw away dirty data from unrelated memory.

  On SoCs that don't define `__L2C_PRESENT`, the code compiles exactly as
  before.

## Applying

```bash
cd ~/zephyrproject/zephyr
git apply --check ~/ZephyrWorkspace/Scratch/patches/0001-*.patch   # dry run
git am ~/ZephyrWorkspace/Scratch/patches/0001-*.patch              # apply as a commit
```

`git am` needs a branch, so create one first if you're on a detached HEAD
(the default after `west init`):

```bash
git switch -c pynqz2-l2
```

Use `git apply` instead of `git am` if you don't want a commit.

`~/zephyrproject/zephyr` is the west manifest repository, so `west update`
does not touch it. Your branch and commit stay in place across `west update`.

### Updating Zephyr later

```bash
cd ~/zephyrproject/zephyr
git fetch origin
git rebase <new-release-tag>      # e.g. v4.6.0; resolve conflicts if any
west update
```

If the rebase conflicts, refresh the patch file afterwards:

```bash
git format-patch -1 -o ~/ZephyrWorkspace/Scratch/patches/
```

### Removing

```bash
git -C ~/zephyrproject/zephyr apply -R ~/ZephyrWorkspace/Scratch/patches/0001-*.patch
```

If you applied it with `git am`, use `git reset --hard HEAD~1` instead.

## Building and running

The patch modifies the Zephyr tree, so do a pristine build after applying
or removing it:

```bash
source ~/zephyrproject/.venv/bin/activate
cd ~/ZephyrWorkspace/Scratch
west build -b pynqz2 scrap -DBOARD_ROOT=$(pwd) -p always
xsct boards/tul/pynqz2/support/pynqz2.tcl
```

`boards/tul/pynqz2/support/pynqz2.tcl` has `set keep_l2 1`:

- `1`: L2 stays enabled. Use this with the patch applied. The script
  cleans+invalidates the L2 after downloading `zephyr.bin`, because Zephyr
  runs with caches off until its MMU is set up.
- `0`: L2 is disabled before loading. Use this with an unpatched Zephyr.

The script prints `L2 control = 0x00000001` when the L2 is on.

## Checking it works

1. `L2 control = 0x00000001` appears in the xsct output.
2. Run the UDP echo test (port 4242, board at 192.168.1.98), for example
   `echo hello | nc -u -w1 192.168.1.98 4242`. Use payloads of different
   sizes, including ones that aren't a multiple of 32 bytes.
3. On the Zephyr shell, `net stats` should not show RX/TX errors increasing.
