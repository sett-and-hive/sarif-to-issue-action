# Threat Model

## Overview

This document describes the security posture of
`sarif-to-issue-action`, the threats identified against its CI/CD
supply chain, and the mitigations applied. It is a living document
and must be updated whenever the threat landscape or mitigations
change.

---

## Assets

| Asset | Description |
|---|---|
| GitHub Actions workflows | CI/CD pipelines that build, test, and publish the action |
| GitHub OIDC / `GITHUB_TOKEN` | Short-lived credentials available inside every workflow run |
| Cloud credentials and secrets | Any environment variables or repository secrets injected into runners |
| Published Docker image | The container image built and scanned by the trivy workflow |
| Renovate bot credentials | Token used by Renovate to open PRs against this repository |

---

## Threats

### T-01 — Third-party GitHub Action supply-chain compromise (CRITICAL)

**Date identified:** 2026-03-19 UTC

**Description:**
Attackers force-pushed 75 of 76 `aquasecurity/trivy-action` release
tags and 7 `aquasecurity/setup-trivy` tags to credential-stealing
malware. The malicious code exfiltrated:

- `GITHUB_TOKEN` and any repository secrets
- Cloud credentials (AWS, GCP, Azure) present in the runner environment
- SSH keys, Kubernetes tokens, and other credentials found in standard locations

Because GitHub Actions resolves mutable tags (e.g. `@v0.9.2`) at
runtime, any workflow referencing an affected tag executed the
malicious payload automatically on the next run — without any change
to the consuming repository.

**Affected versions:** All `aquasecurity/trivy-action` tags except
v0.35.0; all 7 affected `aquasecurity/setup-trivy` tags.

**Verified clean SHA (confirmed by engineering 2026-03-21):**

| Action | Version | Clean SHA |
|---|---|---|
| `aquasecurity/trivy-action` | v0.35.0 | `57a97c7e7821a5776cebc9bb87c984fa69cba8f1` |
| `aquasecurity/setup-trivy` | v0.2.6 | `3fb12ec` *(not used in this repo)* |

**Trivy binary (if managing directly):** v0.69.3, SHA `6fb20c8`
*(not applicable — managed by trivy-action internally)*.

---

## Mitigations

### M-01 — SHA-pin all third-party Actions (IMPLEMENTED)

**Addresses:** T-01

All `uses:` references in every workflow in this repository are
pinned to an immutable commit SHA rather than a mutable tag or
branch. Mutable references cannot be silently redirected to malicious
code when SHAs are used.

**Verification:** `.github/workflows/trivy.yml`

```yaml
# Before (vulnerable — mutable tag)
uses: aquasecurity/trivy-action@1f0aa582c8c8f5f7639610d6d38baddfea4fdcee # 0.9.2

# After (hardened — immutable SHA, verified clean)
uses: aquasecurity/trivy-action@57a97c7e7821a5776cebc9bb87c984fa69cba8f1 # v0.35.0
```

**Commit:** `56dd26b`

---

### M-02 — Egress blocking on CI runners (IMPLEMENTED)

**Addresses:** T-01

`step-security/harden-runner` is deployed in the trivy workflow
with `egress-policy: block`. Only explicitly allow-listed endpoints
can receive outbound connections from the runner. Any attempt by a
compromised action to exfiltrate credentials to an attacker-controlled
server is blocked at the network layer.

**Current allow-list** (`.github/workflows/trivy.yml`):

```text
auth.docker.io:443
deb.debian.org:80
ghcr.io:443
github.com:443
pkg-containers.githubusercontent.com:443
production.cloudflare.docker.com:443
registry-1.docker.io:443
registry.npmjs.org:443
```

`harden-runner` itself is SHA-pinned:
`step-security/harden-runner@df199fb7be9f65074067a9eb93f12bb4c5547cf2`.

---

### M-03 — Renovate version allowlist for trivy-action (IMPLEMENTED)

**Addresses:** T-01

A Renovate `packageRule` restricts automated dependency updates for
`aquasecurity/trivy-action` to versions `>=0.35.0`, the first
confirmed-clean release after the attack. This prevents Renovate from
proposing (and auto-merging) updates to any older,
potentially-compromised version.

**Configuration** (`.github/renovate.json`):

```json
{
  "matchPackageNames": ["aquasecurity/trivy-action"],
  "allowedVersions": ">=0.35.0"
}
```

**Commit:** `97e1e13`

---

### M-04 — Renovate manual-approval gate for setup-trivy (IMPLEMENTED)

**Addresses:** T-01

`aquasecurity/setup-trivy` is not currently used in this repository.
As a proactive control, a Renovate `packageRule` requiring
`dependencyDashboardApproval: true` is in place. Any future adoption
of `setup-trivy` will require a human to explicitly approve the
Renovate PR before it is merged, preventing automatic introduction
of a compromised version.

**Configuration** (`.github/renovate.json`):

```json
{
  "matchPackageNames": ["aquasecurity/setup-trivy"],
  "dependencyDashboardApproval": true
}
```

**Commit:** `97e1e13`

---

## Residual Risk

| Risk | Likelihood | Impact | Notes |
|---|---|---|---|
| Future tag compromise for trivy-action | Low | High | Mitigated by SHA pinning (M-01) and Renovate allowlist (M-03). Any new version must be manually verified before the SHA is updated. |
| Future tag compromise for setup-trivy | Low | High | Not used; gated by M-04 if adopted. |
| New third-party Action not SHA-pinned | Low | High | All current workflow actions are SHA-pinned. Code review must enforce this for any future additions. |
| Egress allow-list gaps | Very Low | Medium | Allow-list is scoped to known-good endpoints. Any newly required endpoint must be explicitly added. |

---

## Response Playbook — Compromised Third-Party Action

1. **Identify** — Receive advisory or CVE notice of a compromised
   action tag.
2. **Quarantine** — Immediately set `egress-policy: audit` or pause
   affected workflows to prevent further credential exposure while
   investigating.
3. **Rotate credentials** — Rotate all secrets that could have been
   exposed: `GITHUB_TOKEN` (via invalidating all active sessions),
   cloud keys, SSH keys, and any repository secrets.
4. **Determine blast radius** — Check GitHub Actions run logs for the
   affected workflow runs during the compromise window. Identify
   whether the malicious code actually executed.
5. **Pin to clean SHA** — Identify the last verified-clean commit SHA
   from the upstream action repository (check the maintainer's
   incident response, release notes, and git history).
6. **Update Renovate allowlist** — Raise the `allowedVersions` floor
   in `renovate.json` to exclude all versions below the
   verified-clean release.
7. **Re-enable workflows** — Update the `uses:` reference to the
   clean SHA and restore normal egress policy.
8. **Document** — Update this threat model with the new threat entry,
   clean SHA, and mitigations applied.

---

## Review Schedule

This threat model is reviewed:

- After any security incident affecting this repository's CI/CD pipeline
- When a new third-party Action is added to any workflow
- At least once per quarter as part of routine security hygiene

<!-- Last updated: 2026-03-21 — trivy supply-chain attack response (T-01) -->
