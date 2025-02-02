# VS code extension needs a makefile at the root directory
MAKE := make

ifeq ($(OS),Windows_NT) 
detected_OS := Windows
else
detected_OS := $(shell sh -c 'uname 2>/dev/null || echo Unknown')
endif
$(info "$(detected_OS)")

ifeq ($(OS),Windows_NT)
cwd := $(shell powershell -c '($$(PWD).Path)')
else
cwd := $(shell sh -c '${PWD} || pwd || echo Unknown')
endif

build:
	zig build -Doptimize=ReleaseFast

safe:
	zig build -Doptimize=ReleaseSafe

build_windows:
	zig build -Dtarget=x86_64-windows -Doptimize=ReleaseFast

build_windows_safe:
	zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe

dagger_windows:
ifeq ($(detected_OS),Linux)
	cd .ci && sh dagger call windows --src=../ export --path=$(cwd)/out/flexapp.exe
endif
ifeq ($(detected_OS),Darwin)
	cd .ci && sh dagger call windows --src=../ export --path=$(cwd)/out/flexapp.exe
endif
ifeq ($(detected_OS),Windows)
	cd .ci && powershell -Command "\
		Start-Process 'dagger' -ArgumentList 'call windows --src=../ export --path=$(cwd)/out/flexapp.exe' -Wait -NoNewWindow"
endif

dagger_linux:
ifeq ($(detected_OS),Linux)
	cd .ci && sh dagger call linux --src=../ export --path=$(cwd)/out/flexapp
endif
ifeq ($(detected_OS),Darwin)
	cd .ci && sh dagger call linux --src=../ export --path=$(cwd)/out/flexapp
endif
ifeq ($(detected_OS),Windows)
	cd .ci && powershell -Command "\
		Start-Process 'dagger' -ArgumentList 'call linux --src=../ export --path=$(cwd)/out/flexapp' -Wait -NoNewWindow"
endif