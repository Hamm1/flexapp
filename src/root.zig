const std = @import("std");
const testing = std.testing;
const main = @import("main.zig");
const helper = @import("helper.zig");
const builtin = @import("builtin");

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
}

test "checking failed download" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    try testing.expect(std.mem.eql(u8, try main.download(allocator, "https://durrrrr.io"), "unknown.txt"));
}

test "checking replacer" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const check = try helper.replace(allocator, "This is a test", "This is a ", "");
    try testing.expect(std.mem.eql(u8, check, "test"));
}

test "checking test_file_path" {
    if (builtin.os.tag == .windows) {
        const check = try helper.test_file_path("C:/Windows/System32/drivers/etc/hosts");
        try testing.expect(check);
    } else {
        const check = try helper.test_file_path("/etc/hosts");
        try testing.expect(check);
    }
}

test "checking test_file_path is false" {
    if (builtin.os.tag == .windows) {
        const check = try helper.test_file_path("C:/Windows/System32/drivers/etc/hosts100");
        try testing.expect(!check);
    } else {
        const check = try helper.test_file_path("/etc/hosts100");
        try testing.expect(!check);
    }
}

test "checking get_last_item with add" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const check = try helper.get_last_item(allocator, "test.txt", ".", true);
    try testing.expect(std.mem.eql(u8, check, ".txt"));
}

test "checking get_last_item without add" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const check = try helper.get_last_item(allocator, "test.txt", ".", false);
    try testing.expect(std.mem.eql(u8, check, "txt"));
}

test "checking concat" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const check = try helper.concat(allocator, "test", ".txt");
    try testing.expect(std.mem.eql(u8, check, "test.txt"));
}

test "checking failed execute installer not found" {
    const result = main.execute("", "", "", "test", .{});
    try testing.expectError(main.ExecuteError.InstallerNotFound, result);
}

test "checking failed execute fpa not found" {
    if (builtin.os.tag == .windows) {
        const result = main.execute("", "", "", "C:/Windows/System32/drivers/etc/hosts", .{});
        try testing.expectError(main.ExecuteError.FpaPackagerNotFound, result);
    } else {
        const result = main.execute("", "", "", "/etc/hosts", .{});
        try testing.expectError(main.ExecuteError.FpaPackagerNotFound, result);
    }
}
