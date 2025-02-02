const std = @import("std");

pub fn replace(allocator: std.mem.Allocator, haystack: []const u8, needle: []const u8, replacement: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();
    var i: usize = 0;
    while (i < haystack.len) {
        if (std.mem.startsWith(u8, haystack[i..], needle)) {
            for (replacement) |c| {
                try result.append(c);
            }
            i += needle.len;
        } else {
            try result.append(haystack[i]);
            i += 1;
        }
    }
    return result.toOwnedSlice();
}
