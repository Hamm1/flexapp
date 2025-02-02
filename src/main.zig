const clap = @import("clap");
const std = @import("std");
const helper = @import("helper.zig");

const Version = struct {
    major: u16,
    minor: u16,
    patch: u16,

    pub fn format(
        self: Version,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("{d}.{d}.{d}", .{ self.major, self.minor, self.patch });
    }
};

const CURRENT_VERSION = Version{
    .major = 0,
    .minor = 1,
    .patch = 0,
};

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();

    // First we specify what parameters our program can take.
    // We can use `parseParamsComptime` to parse a string into an array of `Param(Help)`
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                    Display this help and exit.
        \\-n, --name <str>              Name of package that will be created.
        \\-s, --string <str>...         An option parameter which can be specified multiple times.
        \\-p, --packageversion <str>    Version of the package to be created
        \\-f, --file <str>              Test is file exists.
        \\-i, --installer <str>         Path to package installation binary.
        \\-o, --output <str>            Out package location.
        \\-d, --download <str>          Download a file.
        \\-v, --version                 Output version information
        \\
    );

    // Initialize our diagnostics, which can be used for reporting useful errors.
    // This is optional. You can also pass `.{}` to `clap.parse` if you don't
    // care about the extra information `Diagnostics` provides.
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = gpa.allocator(),
    }) catch |err| {
        // Report useful error and exit
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }
    for (res.args.string) |s| {
        std.debug.print("--string = {s}\n", .{s});
    }
    if (res.args.version != 0) {
        std.debug.print("version = {}\n", .{CURRENT_VERSION});
    }
    if (res.args.file) |f| {
        std.debug.print("file exists = {}\n", .{try test_file_path(f)});
    }
    if (res.args.download) |d| {
        try download(d);
    }
    if (res.args.name) |n| {
        if (res.args.packageversion) |p| {
            if (res.args.output) |o| {
                if (res.args.installer) |i| {
                    try execute(n, p, o, i);
                } else {
                    std.debug.print("{s}\n", .{"Argument for --installer is required"});
                }
            } else {
                std.debug.print("{s}\n", .{"Argument for --output is required"});
            }
        } else {
            std.debug.print("{s}\n", .{"Argument for --packageversion is required"});
        }
    }
    for (res.positionals) |pos| {
        std.debug.print("{s}\n", .{pos});
    }
}

fn test_file_path(path: []const u8) !bool {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        if (err == error.FileNotFound) return false;
        return err;
    };
    defer file.close();
    return true;
}

fn execute(name: []const u8, package_version: []const u8, output: []const u8, installer: []const u8) !void {
    const path = "C:\\program files (x86)\\Liquidware Labs\\FlexApp Packaging Automation\\package-create.exe";
    if (!(try test_file_path(path))) {
        std.debug.print("{s}\n", .{"package-create.exe not found..."});
        return;
    }
    if (!(try test_file_path(installer))) {
        std.debug.print("{s} not found...\n", .{installer});
        return;
    }
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = &[_][]const u8{ path, "package", "/Name", name, "/PackageVersion", package_version, "/Path", output, "/Installer", installer, "/NoSystemRestore" },
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }
    switch (result.term) {
        .Exited => |code| {
            if (code == 0) {
                std.debug.print("Output:\n{s}\n", .{result.stdout});
            } else {
                std.debug.print("Process failed with code: {}\n", .{code});
            }
        },
        .Signal => |sig| {
            std.debug.print("Process terminated by signal: {}\n", .{sig});
        },
        .Stopped => |sig| {
            std.debug.print("Process stopped by signal: {}\n", .{sig});
        },
        .Unknown => |code| {
            std.debug.print("Process terminated with unknown status: {}\n", .{code});
        },
    }
}

fn download(url: []const u8) !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse(url);
    const buf = try allocator.alloc(u8, 1024 * 1024 * 4);
    defer allocator.free(buf);
    var req = try client.open(.GET, uri, .{
        .server_header_buffer = buf,
    });
    defer req.deinit();

    try req.send();
    try req.finish();
    try req.wait();

    if (req.response.status != .ok) {
        std.debug.print("Response Failed: {any}\n", .{req.response.status});
        return;
    }

    var filename: []const u8 = "unknown.txt";
    var iter = req.response.iterateHeaders();
    while (iter.next()) |header| {
        std.debug.print("Name:{s}, Value:{s}\n", .{ header.name, header.value });
        if (std.mem.containsAtLeast(u8, header.value, 1, "attachment; filename=")) {
            var filename1 = std.mem.splitSequence(u8, header.value, "filename=");
            // Consume first iterator
            _ = filename1.first();
            filename = filename1.rest();
            break;
        }
    }

    if (std.mem.eql(u8, filename, "unknown.txt")) {
        var filename1 = std.mem.splitSequence(u8, url, "/");
        while (filename1.next()) |f| {
            filename = f;
        }
    }

    const file = try std.fs.cwd().createFile(
        filename,
        .{ .read = true },
    );
    defer file.close();

    var buffer: [8192]u8 = undefined;
    while (true) {
        const bytes_read = try req.reader().read(&buffer);
        if (bytes_read == 0) break;
        try file.writeAll(buffer[0..bytes_read]);
    }
}
