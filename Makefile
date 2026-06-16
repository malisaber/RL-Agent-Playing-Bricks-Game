SHELL := powershell.exe
.SHELLFLAGS := -NoProfile -ExecutionPolicy Bypass -Command

MATLAB ?= matlab

RUN_SCRIPT := run_bricks.m
MAIN_SCRIPT := src/main.m
BACKUP_DIR := Backup
DATA_FILE := data.mat

.PHONY: all deps run train clean help

all: run

deps:
	if (-not (Get-Command "$(MATLAB)" -ErrorAction SilentlyContinue)) { throw "MATLAB not found on PATH. Install MATLAB with Deep Learning Toolbox." }
	Write-Host "Required MATLAB support: Deep Learning Toolbox (dlnetwork, dlarray, dlfeval, trainingProgressMonitor)."

run: deps
	$(MATLAB) -batch "run('$(RUN_SCRIPT)')"

train: deps
	$(MATLAB) -batch "run('$(MAIN_SCRIPT)')"

clean:
	Remove-Item -LiteralPath "$(DATA_FILE)" -Force -ErrorAction SilentlyContinue
	Remove-Item -LiteralPath "$(BACKUP_DIR)" -Recurse -Force -ErrorAction SilentlyContinue
	Get-ChildItem -Path . -Filter *.asv -File -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue

help:
	Write-Host "Targets:"
	Write-Host "  make deps   Check for MATLAB and required toolboxes"
	Write-Host "  make run    Launch the default training entry point"
	Write-Host "  make train  Run src/main.m directly"
	Write-Host "  make clean  Remove generated data and backup artifacts"
