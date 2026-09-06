# Lab development

Keep shared Lab functionality and regression coverage synchronized with acrogenesis/omarchy on feature/lab-vm. Read [the paired-repository workflow](docs/lab-development.md) before changing Lab code. Run ./test/all and the cross-repository parity check before publishing. Push and verify both repositories for shared changes; packaging paths and plugin identities remain distribution-specific.

## Using the Lab guest

When asked to operate Omarchy Lab or test changes in its guest, read [the omarchy-lab skill](default/agents/skills/omarchy-lab/SKILL.md). It covers controller discovery, guest commands, deployment, checkpoints, visual verification, and authorization boundaries. It does not replace the ISO acceptance harness or authorize changes to the host desktop.
