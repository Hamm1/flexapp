const std = @import("std");
const testing = std.testing;
const main = @import("main.zig");
const helper = @import("helper.zig");
const builtin = @import("builtin");

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

test {
    @import("std").testing.refAllDecls(@This());
    _ = @import("./download.zig");
    _ = @import("./execute.zig");
}

test "basic add functionality" {
    try testing.expect(add(3, 7) == 10);
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

test "replace all function" {
    const allocator = std.testing.allocator;

    const original = "file?name*with<invalid|chars.txt";
    const replaced = try helper.replaceAll(allocator, original, "?8<|*", "_____");
    defer allocator.free(replaced);

    std.debug.print("Original: {s}\n", .{original});
    std.debug.print("Final: {s}\n", .{replaced});

    try std.testing.expect(std.mem.eql(u8, replaced, "file_name_with_invalid_chars.txt"));
}
