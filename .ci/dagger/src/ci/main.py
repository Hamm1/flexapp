import dagger
from dagger import dag, function, object_type


@object_type
class Ci:
    zig_version = "0.15.2"
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
