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
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    
    // First we specify what parameters our program can take.
    // We can use `parseParamsComptime` to parse a string into an array of `Param(Help)`
    const params = comptime clap.parseParamsComptime(
        \\-h, --help                    Display this help and exit.
        \\-n, --name <str>              Name of package that will be created.
        \\-p, --packageversion <str>    Version of the package to be created
        \\-f, --file <str>              Test if file exists.
        \\-i, --installer <str>         Path to package installation binary.
        \\-o, --output <str>            Output location of package build.
        \\-d, --download <str>          Download a file.
        \\-e, --extra <str>...          Extra commands to pass in for packages.
        \\-v, --version                 Output version information
        \\
    );

    // Initialize our diagnostics, which can be used for reporting useful errors.
    // This is optional. You can also pass `.{}` to `clap.parse` if you don't
    // care about the extra information `Diagnostics` provides.
    var diag = clap.Diagnostic{};
    var res = clap.parse(clap.Help, &params, clap.parsers.default, .{
        .diagnostic = &diag,
        .allocator = arena.allocator(),
    }) catch |err| {
        // Report useful error and exit
        diag.report(std.io.getStdErr().writer(), err) catch {};
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        return clap.help(std.io.getStdErr().writer(), clap.Help, &params, .{});
    }
    if (res.args.version != 0) {
        std.debug.print("{}\n", .{CURRENT_VERSION});
    }
    if (res.args.file) |f| {
        std.debug.print("file exists = {}\n", .{try helper.test_file_path(f)});
    }
    if (res.args.download) |d| {
        const allocator = arena.allocator();
        const filename = try download(allocator, d);
        defer allocator.free(filename);
    }
    if (res.args.name) |n| {
        if (res.args.installer) |i| {
            if (res.args.packageversion) |p| {
                if (res.args.output) |o| {
                    try build_package(n, p, o, i, res.args.extra);
                } else {
                    try build_package(n, p, "./", i, res.args.extra);
                }
            } else {
                if (res.args.output) |o| {
                    try build_package(n, "0.0.0.0", o, i, res.args.extra);
                } else {
                    try build_package(n, "0.0.0.0", "./", i, res.args.extra);
                }
            }
        } else {
            std.debug.print("{s}\n", .{"Argument for --installer is required"});
        }
    } else if (res.args.packageversion) |p| {
        if (res.args.installer) |i| {
            if (res.args.output) |o| {
                try build_package("", p, o, i, res.args.extra);
            } else {
                try build_package("", p, "./", i, res.args.extra);
            }
        } else {
            std.debug.print("{s}\n", .{"Argument for --installer is required"});
        }
    } else if (res.args.installer) |i| {
        if (res.args.packageversion) |p| {
            if (res.args.output) |o| {
                try build_package("", p, o, i, res.args.extra);
            } else {
                try build_package("", p, "./", i, res.args.extra);
            }
        } else {
            if (res.args.output) |o| {
                try build_package("", "0.0.0.0", o, i, res.args.extra);
            } else {
                try build_package("", "0.0.0.0", "./", i, res.args.extra);
            }
        }
    }
    for (res.positionals) |pos| {
        std.debug.print("{s}\n", .{pos});
    }
}

fn execute(name: []const u8, package_version: []const u8, output: []const u8, installer: []const u8, extra: anytype) !void {
    // std.debug.print("{s}\n", .{name});
    if (!(try helper.test_file_path(installer))) {
        std.debug.print("{s} not found...\n", .{installer});
        return;
    }
    const path = "C:\\program files (x86)\\Liquidware Labs\\FlexApp Packaging Automation\\fpa-packager.exe";
    if (!(try helper.test_file_path(path))) {
        std.debug.print("{s}\n", .{"fpa-packager.exe not found..."});
        return;
    }
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list = std.ArrayList([]const u8).init(allocator);
    defer list.deinit();

    try list.append(path);
    try list.append("package");
    try list.append("/Name");
    try list.append(name);
    try list.append("/PackageVersion");
    try list.append(package_version);
    try list.append("/Path");
    try list.append(output);
    try list.append("/Installer");
    try list.append(installer);
    try list.append("/NoSystemRestore");

    var list2 = std.ArrayList([]const u8).init(allocator);
    defer list2.deinit();
    for (extra) |pos| {
        try list2.append(pos);
    }
    if (list2.items.len != 0) {
        try list.append("/InstallerArgs");
        for (list2.items) |n|
            try list.append(n);
    }

    const result = try std.process.Child.run(.{
        .allocator = allocator,
        .argv = try list.toOwnedSlice(),
        .max_output_bytes = 500 * 1024,
    });
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }
    switch (result.term) {
        .Exited => |code| {
            if (code == 0) {
                std.debug.print("Output:\nSuccess Code: {}\n", .{code});
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

pub fn download(allocator: std.mem.Allocator, url: []const u8) ![]const u8 {
    std.debug.print("{s} {s}\n", .{ "Starting download for", url });
    var client = std.http.Client{ .allocator = allocator };
    defer client.deinit();

    const uri = try std.Uri.parse(url);
    const buf = try allocator.alloc(u8, 1024 * 1024 * 4);
    defer allocator.free(buf);
    var req = client.open(.GET, uri, .{
        .server_header_buffer = buf,
    }) catch {
        return "unknown.txt";
    };
    defer req.deinit();

    try req.send();
    try req.finish();
    try req.wait();

    if (req.response.status != .ok) {
        std.debug.print("Response Failed: {any}\n", .{req.response.status});
        return "unknown.txt";
    }

    var filename: []const u8 = "unknown.txt";
    var iter = req.response.iterateHeaders();
    while (iter.next()) |header| {
        // std.debug.print("Name:{s}, Value:{s}\n", .{ header.name, header.value });
        if (std.mem.containsAtLeast(u8, header.value, 1, "attachment; filename=")) {
            var filename1 = std.mem.splitSequence(u8, header.value, "filename=");
            // Consume first iterator
            _ = filename1.first();
            filename = filename1.rest();
            // Check for more stuff in filename
            var filename2 = std.mem.splitSequence(u8, filename, ";");
            filename = filename2.first();
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

    filename = try allocator.dupe(u8, filename);
    return filename;
}

fn build_package(name: []const u8, package_version: []const u8, output: []const u8, installer: []const u8, extra: anytype) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    var end_name = name;

    if (std.mem.containsAtLeast(u8, installer, 1, "http://") or std.mem.containsAtLeast(u8, installer, 1, "https://")) {
        const filename = try download(allocator, installer);
        if (!(std.mem.eql(u8, filename, "unknown.txt"))) {
            if (std.mem.eql(u8, name, "")) {
                const new_name = try helper.get_last_item(allocator, filename, ".", true);
                const final_name = try helper.replace(allocator, filename, new_name, "");
                const final_name2 = try helper.replace(allocator, final_name, "Setup", "");
                const final_name3 = try helper.replace(allocator, final_name2, "setup", "");
                end_name = final_name3;
            }
            try execute(end_name, package_version, output, filename, extra);
        } else {
            std.debug.print("{s}\n", .{"Failed to Download file"});
        }
    } else {
        if (std.mem.eql(u8, name, "")) {
            const final_name = try helper.get_last_item(allocator, installer, ".", true);
            const final_name2 = try helper.replace(allocator, installer, final_name, "");
            const final_name3 = try helper.get_last_item(allocator, final_name2, "/", false);
            const final_name4 = try helper.get_last_item(allocator, final_name3, "\\", false);
            const final_name5 = try helper.replace(allocator, final_name4, "Setup", "");
            const final_name6 = try helper.replace(allocator, final_name5, "setup", "");
            end_name = final_name6;
        }
        try execute(end_name, package_version, output, installer, extra);
    }
}
