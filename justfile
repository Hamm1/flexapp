
set shell := ["bash", "-uc"]
set windows-shell := ["pwsh.exe","-c"]
sudo := if os_family() == "windows" { "" } else { "sudo" }

test:
	zig test src/root.zig

build:
	zig build -Doptimize=ReleaseFast

safe:
	zig build -Doptimize=ReleaseSafe

build_windows:
	zig build -Dtarget=x86_64-windows -Doptimize=ReleaseFast

build_windows_safe:
	zig build -Dtarget=x86_64-windows -Doptimize=ReleaseSafe

clean := if os_family() == "windows" { 
		"rm -Recurse -Force -ErrorAction SilentlyContinue './.flox/cache','./.flox/run','./.flox/log', './.flox/env/manifest.lock','zig-out','.zig-cache','out'"
	} else { 
		"rm -rf ./.flox/cache ./.flox/run ./.flox/log ./.flox/env/manifest.lock zig-out .zig-cache out"
	}
clean:
	{{ clean }}

dagger_windows := if os_family() == "windows" { 
		"Start-Process 'dagger' -ArgumentList 'call windows --src=../ export --path=" + invocation_directory() + "/out/flexapp.exe' -Wait -NoNewWindow"
	} else { 
		"dagger call windows --src=../ export --path=" + invocation_directory() + "/out/flexapp.exe"
	}
dagger_windows:
	cd .ci && {{ dagger_windows }}

dagger_linux := if os_family() == "windows" { 
		"Start-Process 'dagger' -ArgumentList 'call linux --src=../ export --path=" + invocation_directory() + "/out/flexapp' -Wait -NoNewWindow"
	} else { 
		"dagger call linux --src=../ export --path=" + invocation_directory() + "/out/flexapp"
	}
dagger_linux:
	cd .ci && {{ dagger_linux }}

flox:
	({{ sudo }} docker run --pull always -v {{invocation_directory()}}:/flexapp -v {{invocation_directory()}}/.flox/build/zshrc:/root/.zshrc -v /var/run/docker.sock:/var/run/docker.sock --name=flox -d -it ghcr.io/flox/flox) || (echo "Container Exists")
	({{ sudo }} docker start flox) || (echo "Container is already started...")
	@{{ sudo }} docker exec -it -w /flexapp flox flox activate

flox_delete:
	{{ sudo }} docker rm -f flox

workspace := if os_family() == "windows" { "{{invocation_directory()}}" } else { "/workspace/flexapp" }
code_server:
	({{ sudo }} docker run -v /var/run/docker.sock:/var/run/docker.sock -v {{invocation_directory()}}:{{ workspace }} --name=code_server -p 443:443 -d matthewhambright/code_server:latest) || (echo "Container Exists")

code_server_use:
	{{ sudo }} docker exec -it code_server zsh

code_server_delete:
	{{ sudo }} docker rm -f code_server