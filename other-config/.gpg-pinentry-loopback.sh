#!/usr/bin/bash
"$(git config --global gpg.cmd)" --pinentry-mode loopback $@
