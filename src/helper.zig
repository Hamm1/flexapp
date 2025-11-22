const std = @import("std");

pub fn replace(allocator: std.mem.Allocator, haystack: []const u8, needle: []const u8, replacement: []const u8) ![]u8 {
    var result: std.ArrayList(u8) = .empty;
    defer result.deinit(allocator);
    var i: usize = 0;
    while (i < haystack.len) {
        if (std.mem.startsWith(u8, haystack[i..], needle)) {
            for (replacement) |c| {
                try result.append(allocator, c);
            }
            i += needle.len;
        } else {
            try result.append(allocator, haystack[i]);
            i += 1;
        }
    }
    return result.toOwnedSlice(allocator);
}
pub fn replaceAll(allocator: std.mem.Allocator, haystack: []const u8, needle: []const u8, replacement: []const u8) ![]u8 {
    var result: std.ArrayList(u8) = .empty;
    defer result.deinit(allocator);
    outer: for (haystack) |c| {
        for (needle, 0..) |ctr, i| {
            if (c == ctr) {
                try result.append(allocator, replacement[i]);
                continue :outer;
            }
        }
        try result.append(allocator, c);
    }
    return result.toOwnedSlice(allocator);
}

pub fn test_file_path(path: []const u8) !bool {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        if (err == error.FileNotFound) return false;
        return err;
    };
    defer file.close();
    return true;
}

pub fn concat(allocator: std.mem.Allocator, current: []const u8, added: []const u8) ![]u8 {
    var result: std.ArrayList(u8) = .empty;
    defer result.deinit(allocator);
    var i: usize = 0;
    while (i < current.len) {
        try result.append(allocator, current[i]);
        i += 1;
    }
    i = 0;
    while (i < added.len) {
        try result.append(allocator, added[i]);
        i += 1;
    }

    return result.toOwnedSlice(allocator);
}

pub fn get_last_item(allocator: std.mem.Allocator, name: []const u8, delimiter: []const u8, add_delimiter_back: bool) ![]u8 {
    var split = std.mem.splitAny(u8, name, delimiter);
    var last: []const u8 = undefined;

    while (split.next()) |item| {
        last = item;
    }
    if (add_delimiter_back) {
        const final = try concat(allocator, delimiter, last);
        return final;
    }
    return try allocator.dupe(u8, last);
}
