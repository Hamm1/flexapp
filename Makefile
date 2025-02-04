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

flox:
	(sudo docker run --pull always -v $(cwd):/flexapp -v $(cwd)/.flox/build/zshrc:/root/.zshrc -v /var/run/docker.sock:/var/run/docker.sock --name=flox -d -it ghcr.io/flox/flox || \
	 docker run --pull always -v $(cwd):/flexapp -v $(cwd)/.flox/build/zshrc:/root/.zshrc -v /var/run/docker.sock:/var/run/docker.sock --name=flox -d -it ghcr.io/flox/flox) || (echo "Container Exists")
	(sudo docker start flox || docker start flox) || (echo "Container is already started...")
	(sudo docker exec -it -w /flexapp flox flox activate || docker exec -it -w /flexapp flox flox activate)

flox_delete:
	sudo docker rm -f flox || docker rm -f flox

code_server:
ifeq ($(detected_OS),Linux)
	(sudo docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(cwd):$(cwd) --name=code_server -p 8080:8080 -d matthewhambright/code_server:latest || \
	 docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(cwd):$(cwd) --name=code_server -p 8080:8080 -d matthewhambright/code_server:latest) || (echo "Container Exists")
endif
ifeq ($(detected_OS),Darwin)
	(sudo docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(cwd):$(cwd) --name=code_server -p 8080:8080 -d matthewhambright/code_server:latest || \
	 docker run -v /var/run/docker.sock:/var/run/docker.sock -v $(cwd):$(cwd) --name=code_server -p 8080:8080 -d matthewhambright/code_server:latest) || (echo "Container Exists")
endif
ifeq ($(detected_OS),Windows)
	(docker run -v //var/run/docker.sock:/var/run/docker.sock -v $(cwd):/workspace/flexapp --name=code_server -p 8080:8080 -d matthewhambright/code_server:latest) || (echo "Container Exists")
endif

code_server_use:
	sudo docker exec -it code_server zsh || docker exec -it code_server zsh

code_server_delete:
	sudo docker rm -f code_server || docker rm -f code_server