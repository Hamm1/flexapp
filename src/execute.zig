const std = @import("std");
const helper = @import("helper.zig");
const testing = std.testing;
const main = @import("main.zig");
const builtin = @import("builtin");

pub const ExecuteError = error{
    InstallerNotFound,
    FpaPackagerNotFound,
    ProcessFailed,
    Canceled,
    SystemResources,
    IsDir,
    WouldBlock,
    AccessDenied,
    Unexpected,
    FileTooBig,
    NoSpaceLeft,
    DeviceBusy,
    PermissionDenied,
    NoDevice,
    FileBusy,
    ProcessFdQuotaExceeded,
    SystemFdQuotaExceeded,
    PathAlreadyExists,
    SymLinkLoop,
    FileNotFound,
    NotDir,
    ReadOnlyFileSystem,
    NetworkNotFound,
    NameTooLong,
    BadPathName,
    PipeBusy,
    AntivirusInterference,
    FileLocksUnsupported,
} || std.mem.Allocator.Error;

pub fn execute(io: std.Io, name: []const u8, package_version: []const u8, output: []const u8, installer: []const u8, extra: anytype) anyerror![]const u8 {
    // std.debug.print("{s}\n", .{name});
    if (!(try helper.test_file_path(io, installer))) {
        std.debug.print("{s} not found...\n", .{installer});
        return ExecuteError.InstallerNotFound;
    }
    const path = "C:\\program files (x86)\\Liquidware Labs\\FlexApp Packaging Automation\\fpa-packager.exe";
    if (!(try helper.test_file_path(io, path))) {
        std.debug.print("{s}\n", .{"fpa-packager.exe not found..."});
        return ExecuteError.FpaPackagerNotFound;
    }
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var list: std.ArrayList([]const u8) = .empty;
    defer list.deinit(allocator);

    try list.append(allocator, path);
    try list.append(allocator, "package");
    try list.append(allocator, "/Name");
    try list.append(allocator, name);
    try list.append(allocator, "/PackageVersion");
    try list.append(allocator, package_version);
    try list.append(allocator, "/Path");
    try list.append(allocator, output);
    try list.append(allocator, "/Installer");
    try list.append(allocator, installer);
    try list.append(allocator, "/NoSystemRestore");

    var list2: std.ArrayList([]const u8) = .empty;
    defer list2.deinit(allocator);
    for (extra) |pos| {
        try list2.append(allocator, pos);
    }
    if (list2.items.len != 0) {
        try list.append(allocator, "/InstallerArgs");
        for (list2.items) |n|
            try list.append(allocator, n);
    }

    const result = try std.process.run(allocator, io, .{
        .argv = try list.toOwnedSlice(allocator),
        .stdout_limit = @enumFromInt(500 * 1024),
        .stderr_limit = @enumFromInt(500 * 1024),
    });
    defer allocator.free(result.stdout);
    defer allocator.free(result.stderr);
    defer {
        allocator.free(result.stdout);
        allocator.free(result.stderr);
    }
    switch (result.term) {
        .exited => |code| {
            if (code == 0) {
                std.debug.print("Output:\nSuccess Code: {}\n", .{code});
                return "Success";
            } else {
                std.debug.print("Process failed with code: {}\n", .{code});
                return ExecuteError.ProcessFailed;
            }
        },
        .signal => |sig| {
            std.debug.print("Process terminated by signal: {}\n", .{sig});
            return ExecuteError.ProcessFailed;
        },
        .stopped => |sig| {
            std.debug.print("Process stopped by signal: {}\n", .{sig});
            return ExecuteError.ProcessFailed;
        },
        .unknown => |code| {
            std.debug.print("Process terminated with unknown status: {}\n", .{code});
            return ExecuteError.ProcessFailed;
        },
    }
}

test "checking failed execute installer not found" {
    const io = std.Io.Threaded.global_single_threaded.io();
    const result = execute(io, "", "", "", "test", .{});
    try testing.expectError(ExecuteError.InstallerNotFound, result);
}

test "checking failed execute fpa not found" {
    const io = std.Io.Threaded.global_single_threaded.io();
    if (builtin.os.tag == .windows) {
        const result = execute(io, "", "", "", "C:/Windows/System32/drivers/etc/hosts", .{});
        try testing.expectError(ExecuteError.FpaPackagerNotFound, result);
    } else {
        const result = execute(io, "", "", "", "/etc/hosts", .{});
        try testing.expectError(ExecuteError.FpaPackagerNotFound, result);
    }
}
