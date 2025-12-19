const std = @import("std");
const helper = @import("helper.zig");
const testing = std.testing;

pub fn download(allocator: std.mem.Allocator, url: []const u8) ![]const u8 {
    std.debug.print("{s} {s}\n", .{ "Starting download for", url });

    var client = std.http.Client{
        .allocator = allocator,
    };
    defer client.deinit();

    try client.ca_bundle.rescan(allocator);
    // defer client.ca_bundle.deinit(allocator);
    // std.debug.print("CA bundle size: {}\n", .{client.ca_bundle.bytes.items.len});

    const uri = try std.Uri.parse(url);
    var buf: [8192]u8 = undefined;
    var req = client.request(.GET, uri, .{
        .redirect_behavior = @enumFromInt(65000),
        .keep_alive = false,
    }) catch |err| {
        std.debug.print("Error creating request: {}\n", .{err});
        return "unknown.txt";
    };
    defer req.deinit();

    req.redirect_behavior = @enumFromInt(65000);
    try req.sendBodiless();
    var response = try req.receiveHead(&buf);

    if (response.head.status != .ok) {
        if (response.head.status != .found) {
            std.debug.print("Response Failed: {any}\n", .{response.head.status});
            return "unknown.txt";
        }
    }

    var filename: []const u8 = "unknown.txt";
    var iter = response.head.iterateHeaders();
    while (iter.next()) |header| {
        std.debug.print("Name:{s}, Value:{s}\n", .{ header.name, header.value });
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

        filename = try helper.replaceAll(allocator, filename, "?*<|", "_____");
    }
    const filename_final = try allocator.dupe(u8, filename);

    const file = try std.fs.cwd().createFile(
        filename,
        .{ .read = true },
    );
    allocator.free(filename);
    defer file.close();

    var buffer: [64]u8 = undefined;
    const decompress_buffer: []u8 = switch (response.head.content_encoding) {
        .identity => &.{},
        .zstd => try allocator.alloc(u8, std.compress.zstd.default_window_len),
        .deflate, .gzip => try allocator.alloc(u8, std.compress.flate.max_window_len),
        .compress => return error.UnsupportedCompressionMethod,
    };
    defer allocator.free(decompress_buffer);

    var transfer_buffer: [64]u8 = undefined;
    var decompress: std.http.Decompress = undefined;
    const reader = response.readerDecompressing(&transfer_buffer, &decompress, decompress_buffer);

    var file_writer: std.fs.File.Writer = .init(file, &buffer);
    _ = reader.streamRemaining(&file_writer.interface) catch |err| {
        std.debug.print("Error during download/decompression: {}\n", .{err});
        return "unknown.txt";
    };
    // Flush remaining buffer just in case.
    try file_writer.interface.flush();

    return filename_final;
}

test "checking failed download" {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    try testing.expect(std.mem.eql(u8, try download(allocator, "https://durrrrr.io"), "unknown.txt"));
}

test "download function" {
    const testing_allocator = std.testing.allocator;

    const url = "https://dl.google.com/dl/chrome/install/googlechromestandaloneenterprise64.msi";
    const filename = try download(testing_allocator, url);
    defer testing_allocator.free(filename);
    std.debug.print("Downloaded file: {s}\n", .{filename});
}
