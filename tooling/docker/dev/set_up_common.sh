#!/bin/sh -e
# OS-agnostic machine setup steps for DXR. This is reusable for prod, as we
# don't do anything specific to development or CI.

# Install Rust.
curl https://sh.rustup.rs -sSf | sh -s -- -v -y
