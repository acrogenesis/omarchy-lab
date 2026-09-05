# Validation

This standalone preview is extracted from the native Lab implementation after its review fixes. Automated coverage and live use are complementary; neither means every installer/environment combination has been tested.

## Automated

`./test/all` runs shell syntax checks plus standalone-path, panel/model, viewer, workbench and review-regression suites. Coverage includes checkpoints surviving gold replacement, failed deployments not recording success or rebooting, bounded read-only health, safe authentication cancellation, network transitions, profile ceilings, recording cleanup, and guest terminal lifetime.

The standalone-path suite keeps `OMARCHY_PATH` pointed at a separate host fixture and tests command routing, spaces in the package path, private command resolution, desktop/SSH entries, manifest identity and shipped guest assets.

## Live development validation

The native implementation was exercised on an actual Omarchy Quickshell desktop and an independent disposable VM clone: branch deploy/sync, failed rsync, marker-based checkpoint restore after gold promotion, both offline network-source transitions, resource power cycles, clipboard/file round trips, screenshots/recording, viewer ratios/settings, and Stop with an in-flight health poll. The original development VM was not used for destructive reset/rebuild tests.

After extraction, the real external-plugin installer cloned and enabled `acrogenesis.lab`. Console, Develop, Environment, Capture and Automate were visually inspected in the running Quickshell desktop. Bundled health returned a healthy existing guest with its original boot ID; Reload Hyprland succeeded through the external panel. Package relocation, including a path with spaces and a separate host runtime, passes automated tests. Manifest validation and QML lint passed. The temporary external installation was removed after testing; the native Lab and guest were preserved. This does not establish fresh installation coverage.

## Outstanding coverage

Fresh/nested install follow-up (2026-09-05): reproduced missing core/extra/multilib/omarchy databases inside an outer Lab VM. The installer recovered through a normal Omarchy update and installed all ten declared hypervisor/SSH dependencies. Reproduced the outer-network conflict with libvirt's default subnet; setup safely selected 192.168.124.0/24. A clean second run of the complete installer with 4 GiB RAM, 4 CPUs and a 40-GiB disk completed ISO installation, guest package/database bootstrap, display-agent setup, gold/overlay creation and reboot. Verified the generated SSH shortcut, passwordless sudo validation, active display-resize service and a visible nested desktop in virt-viewer. The viewer was launched separately with the graphical session environment because the test installer ran over SSH.

The first diagnostic install was discarded and recreated; only the disposable nested VM was replaced. A Quickshell lockscreen abort was observed during shell-wide plugin reload in the outer guest. Lab setup no longer performs that unnecessary rescan; the outer shell was restored, and the final bar-enable step and viewer passed without another crash. This avoids the installer trigger, not a general fix for Quickshell reload bugs.

- Fresh full ISO installation now passes the nested end-to-end run above. The separate gold-rebuild command and authenticated reset still need another end-to-end run for the extracted release.
- Intermittent firmware/boot delays remain under investigation.
- TPM state is shared across checkpoints; cloning a disk into a new TPM is not equivalent to restoring a checkpoint.
- Test on smaller hosts and different GPUs before recommending this for unattended or security-sensitive workloads.
