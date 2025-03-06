import dagger
from dagger import dag, function, object_type

@object_type
class Ci:
    
    zig_version = "zig-linux-x86_64-0.14.0"

    @function
    async def linux(self, src: dagger.Directory) -> dagger.File:   
        return (
            dag.container()
            .from_("ubuntu:24.04")
            .with_mounted_directory("/src", src)
            .with_workdir("/src")
            .with_exec(["apt-get", "update"])
            .with_exec(["apt-get", "install", "-y", "curl", "tar", "xz-utils"])
            .with_exec(["curl", f"https://ziglang.org/builds/{self.zig_version}.tar.xz","--output", "/tmp/zig.tar.xz"])
            .with_exec(["tar", "-xf", "/tmp/zig.tar.xz", "-C", "/tmp"])
            .with_exec(["mkdir", "/root/.zig"])
            .with_exec(["cp", "-r", f"/tmp/{self.zig_version}/.", "/root/.zig/"])
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
            .with_exec(["curl", f"https://ziglang.org/builds/{self.zig_version}.tar.xz","--output", "/tmp/zig.tar.xz"])
            .with_exec(["tar", "-xf", "/tmp/zig.tar.xz", "-C", "/tmp"])
            .with_exec(["mkdir", "/root/.zig"])
            .with_exec(["cp", "-r", f"/tmp/{self.zig_version}/.", "/root/.zig/"])
            .with_exec(["chmod", "777", "/root/.zig"])
            .with_exec(["/root/.zig/zig", "build", "-Dtarget=x86_64-windows", "-Doptimize=ReleaseSafe"])
            .file("zig-out/bin/flexapp.exe")
        )