const clap = @import("clap");
const std = @import("std");
const helper = @import("helper.zig");
const download = @import("download.zig").download;
const execute = @import("execute.zig").execute;

const Version = struct {
    major: u16,
    minor: u16,
    patch: u16,

    pub fn format(
        self: Version,
        writer: anytype,
    ) !void {
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
        try diag.reportToFile(.stderr(), err);
        return err;
    };
    defer res.deinit();

    if (res.args.help != 0) {
        return clap.helpToFile(.stderr(), clap.Help, &params, .{});
    }
    if (res.args.version != 0) {
        std.debug.print("{f}\n", .{CURRENT_VERSION});
    }
    if (res.args.file) |f| {
        std.debug.print("file exists = {}\n", .{try helper.test_file_path(f)});
    }
    if (res.args.download) |d| {
        const allocator = arena.allocator();
        _ = try download(allocator, d);
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
            const result = execute(end_name, package_version, output, filename, extra) catch |err| {
                std.debug.print("Error executing: {}\n", .{err});
                return err;
            };
            std.debug.print("Execution result: {s}\n", .{result});
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
        const result = execute(end_name, package_version, output, installer, extra) catch |err| {
            std.debug.print("Error executing: {}\n", .{err});
            return err;
        };
        std.debug.print("Execution result: {s}\n", .{result});
    }
}
