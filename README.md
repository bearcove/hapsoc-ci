DEPRECATED: All hapsoc repositories are now using github-hosted runners, which
is less of a maintenance burden.

# hapsoc-ci

This is a fly.io machine definition that runs jobs for <https://github.com/hapsoc>

It ships with a full Rust/C/C++ toolchain and some Rust-specific tools (nextest,
udeps, llvm-cov etc.)

## Secrets

`GITHUB_ACTIONS_TOKEN` is the Github Actions self-hosted runner registration
token.
