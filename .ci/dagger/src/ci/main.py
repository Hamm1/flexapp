import dagger
from dagger import dag, function, object_type


@object_type
class Ci:
    zig_version = "0.17.0"
    zig_binary = f"zig-x86_64-linux-{zig_version}"

    @function
    async def tests(self, src: dagger.Directory) -> dagger.Container:
        return (
            dag.container()
            .from_("ubuntu:24.04")
            .with_mounted_directory("/src", src)
            .with_workdir("/src")
            .with_exec(["apt-get", "update"])
            .with_exec(["apt-get", "install", "-y", "curl", "tar", "xz-utils"])
            .with_exec(["curl", f"https://ziglang.org/download/{self.zig_version}/{self.zig_binary}.tar.xz", "--output", "/tmp/zig.tar.xz"])
            .with_exec(["tar", "-xf", "/tmp/zig.tar.xz", "-C", "/tmp"])
            .with_exec(["mkdir", "/root/.zig"])
            .with_exec(["cp", "-r", f"/tmp/{self.zig_binary}/.", "/root/.zig/"])
            .with_exec(["chmod", "777", "/root/.zig"])
            .with_exec(["/root/.zig/zig", "test", "src/root.zig", "-OReleaseSafe"])
        )

    @function
    async def linux(self, src: dagger.Directory) -> dagger.File:
        return (
            dag.container()
            .from_("ubuntu:24.04")
            .with_mounted_directory("/src", src)
            .with_workdir("/src")
            .with_exec(["apt-get", "update"])
            .with_exec(["apt-get", "install", "-y", "curl", "tar", "xz-utils"])
            .with_exec(["curl", f"https://ziglang.org/download/{self.zig_version}/{self.zig_binary}.tar.xz", "--output", "/tmp/zig.tar.xz"])
            .with_exec(["tar", "-xf", "/tmp/zig.tar.xz", "-C", "/tmp"])
            .with_exec(["mkdir", "/root/.zig"])
            .with_exec(["cp", "-r", f"/tmp/{self.zig_binary}/.", "/root/.zig/"])
            .with_exec(["chmod", "777", "/root/.zig"])
            .with_exec(["/root/.zig/zig", "build", "-Doptimize=ReleaseSafe"])
            .file("zig-out/bin/flexapp")
        )

    @function
    async def windows(self, src: dagger.Directory) -> dagger.File:
        return (
            dag.container()
            .from_("ubuntu:24.04")
            .with_mounted_directory("/src", src)
            .with_workdir("/src")
            .with_exec(["apt-get", "update"])
            .with_exec(["apt-get", "install", "-y", "curl", "tar", "xz-utils"])
            .with_exec(["curl", f"https://ziglang.org/download/{self.zig_version}/{self.zig_binary}.tar.xz", "--output", "/tmp/zig.tar.xz"])
            .with_exec(["tar", "-xf", "/tmp/zig.tar.xz", "-C", "/tmp"])
            .with_exec(["mkdir", "/root/.zig"])
            .with_exec(["cp", "-r", f"/tmp/{self.zig_binary}/.", "/root/.zig/"])
            .with_exec(["chmod", "777", "/root/.zig"])
            .with_exec(["/root/.zig/zig", "build", "-Dtarget=x86_64-windows", "-Doptimize=ReleaseSafe"])
            .file("zig-out/bin/flexapp.exe")
        )

    @function
    async def nix(self, src: dagger.Directory, cmd: str = "test", file: str = "zig-out/bin/flexapp") -> dagger.Container:
        nix_store_cache = dag.cache_volume("nix-store")
        return (
            dag.container()
            .from_("debian:trixie@sha256:f324c7ff54321e8d9c588493a20244965938ce0aa50bbd1022d38010e9ffc4b1")
            .with_mounted_cache("/nix", nix_store_cache)
            .with_exec(["apt-get", "update"])
            .with_exec(["apt-get", "install", "-y", "curl", "xz-utils", "build-essential"])
            .with_exec(["sh", "-c", "curl -L https://install.determinate.systems/nix | sh -s -- install linux --init none --no-confirm"])
            .with_env_variable("PATH", "/nix/var/nix/profiles/default/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin")
            .with_env_variable(
                "NIX_CONFIG",
                "experimental-features = nix-command flakes\nsandbox = false\nbuild-users-group =",
            )
            .with_mounted_directory("/src", src)
            .with_workdir("/src")
            .with_exec(["nix", "run", f".#{cmd}"])
            .file(f"{file}")
        )
