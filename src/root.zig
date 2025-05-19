const std = @import("std");
const testing = std.testing;
const main = @import("main.zig");

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
