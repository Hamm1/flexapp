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

pub fn test_file_path(path: []const u8) !bool {
    const file = std.fs.cwd().openFile(path, .{}) catch |err| {
        if (err == error.FileNotFound) return false;
        return err;
    };
    defer file.close();
    return true;
}

pub fn concat(allocator: std.mem.Allocator, current: []const u8, added: []const u8) ![]u8 {
    var result = std.ArrayList(u8).init(allocator);
    defer result.deinit();
    var i: usize = 0;
    while (i < current.len) {
        try result.append(current[i]);
        i += 1;
    }
    i = 0;
    while (i < added.len) {
        try result.append(added[i]);
        i += 1;
    }

    return result.toOwnedSlice();
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
