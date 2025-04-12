# Makefile for syncing Kodi skin TO a local Git repo and managing Git
# --- !!! IMPORTANT !!! ---
# This Makefile is intended to be run FROM the Kodi addon directory
# on the Shield (e.g., /Volumes/internal/.../skin.altus/)
# after it has been placed there (likely via addon installation/update).
# It syncs files FROM the current directory TO the specified Mac Git repo.
# Git commands are executed ON the Mac Git repo.

# --- Configuration ---
# Source: The current directory where this Makefile is run from.
#         This should be the addon dir on the mounted Shield share.
#         Add a trailing slash!
SOURCE_DIR := ./

# Destination: Path to your stable local Git repository clone on your Mac.
#              Uses the HOME environment variable for portability across machines.
#              Assumes the repo is at '~/DEV/skin.altus/'. Add a trailing slash!
DEST_DIR := $(HOME)/DEV/skin.altus/

# rsync options:
# -a: archive mode (recursive, preserves permissions, times, symlinks, etc.)
# -v: verbose (show files being transferred)
# -h: human-readable file sizes
# --delete: delete files in DEST_DIR that no longer exist in SOURCE_DIR (current dir)
#           Use with caution! Ensures Mac repo mirrors the Shield dir state.
# --exclude: patterns for files/dirs to ignore during sync
RSYNC_OPTS := -avh --delete
# Exclude Git files (.git/, .gitignore), Makefile, AppleDouble (._*), and common transient files
EXCLUDE_OPTS := --exclude='.git/' --exclude='.gitignore' --exclude='Makefile' --exclude='._*' --exclude='.DS_Store' --exclude='*.pyo' --exclude='*.pyc' --exclude='cache/' --exclude='Thumbs.db'

# Git commit message variable (used like: make commit m="Your message")
m ?= ""

# Default shell
SHELL := /bin/bash
# --- End Configuration ---

# Use .PHONY for targets that don't represent actual files
.PHONY: all sync test_sync status add commit push clean help check_dest

# Default target (if you just run 'make')
all: help

help:
	@echo "--- Makefile executed from: $(shell pwd) ---"
	@echo "Available targets (run from Shield addon dir):"
	@echo "  make check_dest - Verify destination Git repo ($(DEST_DIR)) exists."
	@echo "  make sync       - Sync changes FROM here TO the Mac Git repo ($(DEST_DIR))."
	@echo "  make test_sync  - Perform a DRY RUN of the sync process (shows changes without applying)."
	@echo "  --- Git commands executed on Mac Repo ($(DEST_DIR)) ---"
	@echo "  make status     - Run 'git status' in the Mac repository."
	@echo "  make add        - Run 'git add .' in the Mac repository."
	@echo "  make commit m=\"Message\" - Commit staged changes in the Mac repository."
	@echo "  make push       - Run 'git push' from the Mac repository."
	@echo "  make clean      - (Caution!) Run 'git clean -fdx' in the Mac repository."
	@echo "  make help       - Show this help message."

# Target to check if the destination directory is accessible
check_dest:
	@echo "Checking destination directory..."
	@# Attempt to expand ~ within the shell command for a more robust check
	DEST_DIR_EXPANDED=`eval echo $(DEST_DIR)` ; \
	echo "Checking expanded path: $$DEST_DIR_EXPANDED" ; \
	if [ ! -d "$$DEST_DIR_EXPANDED" ]; then \
		echo "ERROR: Destination Git repository not found: $(DEST_DIR) (Expanded: $$DEST_DIR_EXPANDED)"; \
		echo "Please ensure the path is correct ('~/DEV/skin.altus/' exists) and the directory exists."; \
		exit 1; \
	elif [ ! -d "$$DEST_DIR_EXPANDED.git" ]; then \
	    echo "ERROR: Destination directory exists, but does not appear to be a Git repository: $$DEST_DIR_EXPANDED"; \
	    echo "       (.git directory not found)"; \
	    exit 1; \
	else \
		echo "Destination Git repository ($(DEST_DIR)) found."; \
	fi


# Target to sync files FROM current dir TO the Mac Git repo
sync: check_dest
	@echo "Syncing changes FROM '$(shell pwd)' TO Mac Git Repo..."
	@echo "Source:      $(SOURCE_DIR) (Current Directory)"
	@echo "Destination: $(DEST_DIR)"
	@echo "Running: rsync $(RSYNC_OPTS) $(EXCLUDE_OPTS) \"$(SOURCE_DIR)\" \"$(DEST_DIR)\""
	@rsync $(RSYNC_OPTS) $(EXCLUDE_OPTS) "$(SOURCE_DIR)" "$(DEST_DIR)"
	@echo "Sync complete. Run 'make status' to check Git status in Mac Repo."

# Target to perform a dry run sync
test_sync: check_dest
	@echo "Performing DRY RUN sync FROM '$(shell pwd)' TO Mac Git Repo..."
	@echo "Source:      $(SOURCE_DIR) (Current Directory)"
	@echo "Destination: $(DEST_DIR)"
	@echo "Running: rsync $(RSYNC_OPTS) --dry-run $(EXCLUDE_OPTS) \"$(SOURCE_DIR)\" \"$(DEST_DIR)\""
	@rsync $(RSYNC_OPTS) --dry-run $(EXCLUDE_OPTS) "$(SOURCE_DIR)" "$(DEST_DIR)"
	@echo "Dry run complete. No files were changed. Review the output above."

# --- Git Targets (executed on DEST_DIR) ---

status: check_dest
	@echo "Running 'git status' in Mac Repo ($(DEST_DIR))..."
	@git -C "$(DEST_DIR)" status

add: check_dest
	@echo "Running 'git add .' in Mac Repo ($(DEST_DIR))..."
	@git -C "$(DEST_DIR)" add .
	@echo "Use 'make status' to see staged changes in Mac Repo."

commit: check_dest
	@echo "Attempting commit in Mac Repo ($(DEST_DIR))..."
	@if [ -z "$(m)" ]; then \
		echo "ERROR: Commit message required."; \
		echo "Usage: make commit m=\"Your commit message\""; \
		exit 1; \
	fi
	@echo "Running 'git -C \"$(DEST_DIR)\" commit -m \"$(m)\"'..."
	@git -C "$(DEST_DIR)" commit -m "$(m)"
	@echo "Commit successful in Mac Repo."

push: check_dest
	@echo "Running 'git push' from Mac Repo ($(DEST_DIR))..."
	@git -C "$(DEST_DIR)" push
	@echo "Push attempted from Mac Repo. Check output for status."

clean: check_dest
	@echo "WARNING: This will remove all untracked files and directories"
	@echo "         from your Mac Git repository ($(DEST_DIR))."
	@# Adding an extra check to ensure the user understands *where* clean runs
	DEST_DIR_EXPANDED=`eval echo $(DEST_DIR)` ; \
	read -p "Clean untracked files in Mac Repo '$$DEST_DIR_EXPANDED'? (y/N): " confirm && [[ $$confirm == [yY] || $$confirm == [yY][eE][sS] ]] || exit 1
	@echo "Running 'git clean -fdx' in Mac Repo ($(DEST_DIR))..."
	@git -C "$(DEST_DIR)" clean -fdx
	@echo "Untracked files removed from Mac Repo."