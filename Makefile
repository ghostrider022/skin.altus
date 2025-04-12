# Makefile for syncing Kodi skin from Shield and managing Git repo

# --- Configuration ---
# Source: Path to the skin folder on the *mounted* Shield network share.
# IMPORTANT: Ensure this path is correct and the share is mounted before running make.
#            Add a trailing slash!
SOURCE_DIR := /Volumes/internal/Android/data/org.xbmc.kodi/files/.kodi/addons/skin.altus/

# Destination: The current directory where this Makefile resides.
#              Represents your local Git repository. Add a trailing slash!
DEST_DIR := ./

# rsync options:
# -a: archive mode (recursive, preserves permissions, times, symlinks, etc.)
# -v: verbose (show files being transferred)
# -h: human-readable file sizes
# --delete: delete files in DEST_DIR that no longer exist in SOURCE_DIR
#           Use with caution! Ensures local repo is an exact mirror.
#           Remove if you want to keep locally deleted files temporarily.
# --exclude: patterns for files/dirs to ignore during sync
RSYNC_OPTS := -avh --delete
EXCLUDE_OPTS := --exclude='.git/' --exclude='.DS_Store' --exclude='*.pyo' --exclude='*.pyc' --exclude='cache/' --exclude='Thumbs.db' --exclude='Makefile'

# Git commit message variable (used like: make commit m="Your message")
m ?= ""

# Default shell
SHELL := /bin/bash
# --- End Configuration ---

# Use .PHONY for targets that don't represent actual files
.PHONY: all sync test_sync status add commit push clean help check_dirs

# Default target (if you just run 'make')
all: help

help:
	@echo "Available targets:"
	@echo "  make check_dirs - Verify source directory exists (Shield mounted?)."
	@echo "  make sync       - Sync changes from Shield ($(SOURCE_DIR)) to here ($(DEST_DIR))."
	@echo "  make test_sync  - Perform a DRY RUN of the sync process (shows changes without applying)."
	@echo "  make status     - Run 'git status' in the local repository."
	@echo "  make add        - Run 'git add .' to stage all changes."
	@echo "  make commit m=\"Your message\" - Commit staged changes with a message."
	@echo "  make push       - Run 'git push' to push committed changes."
	@echo "  make clean      - (Caution!) Removes untracked files/dirs from local repo (git clean -fdx)."
	@echo "  make help       - Show this help message."

# Target to check if the source directory is accessible
check_dirs:
	@echo "Checking source directory..."
	@if [ ! -d "$(SOURCE_DIR)" ]; then \
		echo "ERROR: Source directory not found or Shield not mounted: $(SOURCE_DIR)"; \
		echo "Please ensure the Shield network share ('internal'?) is mounted at /Volumes/"; \
		exit 1; \
	else \
		echo "Source directory ($(SOURCE_DIR)) found."; \
	fi
	@echo "Destination directory is the current directory: $(shell pwd)"

# Target to sync files from Shield to local repo
sync: check_dirs
	@echo "Syncing changes from Shield -> Local Git Repo..."
	@echo "Source:      $(SOURCE_DIR)"
	@echo "Destination: $(DEST_DIR)"
	@echo "Running: rsync $(RSYNC_OPTS) $(EXCLUDE_OPTS) \"$(SOURCE_DIR)\" \"$(DEST_DIR)\""
	@rsync $(RSYNC_OPTS) $(EXCLUDE_OPTS) "$(SOURCE_DIR)" "$(DEST_DIR)"
	@echo "Sync complete. Check 'make status' for changes."

# Target to perform a dry run sync
test_sync: check_dirs
	@echo "Performing DRY RUN sync from Shield -> Local Git Repo..."
	@echo "Source:      $(SOURCE_DIR)"
	@echo "Destination: $(DEST_DIR)"
	@echo "Running: rsync $(RSYNC_OPTS) --dry-run $(EXCLUDE_OPTS) \"$(SOURCE_DIR)\" \"$(DEST_DIR)\""
	@rsync $(RSYNC_OPTS) --dry-run $(EXCLUDE_OPTS) "$(SOURCE_DIR)" "$(DEST_DIR)"
	@echo "Dry run complete. No files were changed. Review the output above."

# --- Git Targets ---

status:
	@echo "Running 'git status'..."
	@git status

add:
	@echo "Running 'git add .' to stage all changes..."
	@git add .
	@echo "Use 'make status' to see staged changes."

commit:
	@echo "Attempting commit..."
	@if [ -z "$(m)" ]; then \
		echo "ERROR: Commit message required."; \
		echo "Usage: make commit m=\"Your commit message\""; \
		exit 1; \
	fi
	@echo "Running 'git commit -m \"$(m)\"'..."
	@git commit -m "$(m)"
	@echo "Commit successful."

push:
	@echo "Running 'git push'..."
	@git push
	@echo "Push attempted. Check output for status."

clean:
	@echo "WARNING: This will remove all untracked files and directories"
	@echo "         from your local repository ($(shell pwd))."
	@read -p "Are you sure? (y/N): " confirm && [[ $$confirm == [yY] || $$confirm == [yY][eE][sS] ]] || exit 1
	@echo "Running 'git clean -fdx'..."
	@git clean -fdx
	@echo "Untracked files removed."