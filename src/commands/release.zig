const std = @import("std");
const mem = @import("std").mem;
const Command = @import("../command.zig").Command;
const commands = @import("../command.zig").commands;
const pendingChangelogDir = @import("new.zig").pendingChangelogDir;

pub const release = .{
    "release",
    Command{ .version = "0.0.1", .help = "release a new version", .run = releaseCommand },
};

pub fn releaseCommand(init: std.process.Init, args: []const [:0]const u8) !void {
    // meaning that it was invoked by ./bin list
    if (args.len == 2) {
        if (changelogFileExists(init) and
            !changelogFileIsEmpty(init))
        {
            std.log.info("changelog file already exists and not empty\n", .{});
            const contents = try getContent(init);
            if (contents.len == 0) {
                std.log.warn(pendingChangelogDir ++ " does not contain any changelogs", .{});
            } else {
                try writeToChangelogFile(init, contents);
            }
        } else {
            std.log.info("changelog file does not exist or is empty, cancelling operation\n", .{});
        }
        return;
    }
    // if the first argument is --help
    if (std.mem.eql(u8, args[2], "--help")) {
        std.log.info("{s}\n", .{release.@"1".help});
        return;
    }
    // if the first argument is --version
    if (std.mem.eql(u8, args[2], "--version")) {
        std.log.info("release command version {s}\n", .{release.@"1".version});
        return;
    }
}

fn changelogFileExists(
    init: std.process.Init,
) bool {
    const changelogFile: ?std.Io.File = std.Io.Dir.cwd().openFile(init.io, "CHANGELOG.md", .{}) catch null;
    if (changelogFile) |changelogF| {
        defer changelogF.close(init.io);
        return true;
    } else {
        return false;
    }
}

fn changelogFileIsEmpty(
    init: std.process.Init,
) bool {
    const changelogFile: ?std.Io.File = std.Io.Dir.cwd().openFile(init.io, "CHANGELOG.md", .{}) catch null;
    if (changelogFile) |changelogF| {
        defer changelogF.close(init.io);
        std.log.info("changelog file already exists\n", .{});
        var content: [1]u8 = @splat('A');
        var file_reader = changelogF.reader(init.io, &.{});
        const reader = &file_reader.interface;

        const bytes_read: usize = reader.readSliceShort(&content) catch 0;
        return bytes_read == 0;
    } else {
        return false;
    }
}

fn getContent(
    init: std.process.Init,
) ![][]const u8 {
    const allocator = init.arena.allocator();

    var files: std.ArrayList([]const u8) = .empty;

    const changelogDir: ?std.Io.Dir = std.Io.Dir.cwd().openDir(init.io, pendingChangelogDir, .{ .iterate = true }) catch null;

    if (changelogDir) |dir| {
        defer dir.close(init.io);

        var walker = try dir.walk(allocator);
        defer walker.deinit();

        while (try walker.next(init.io)) |entry| {
            if (entry.kind != .file) continue;

            const content = try dir.readFileAlloc(
                init.io,
                entry.path,
                allocator,
                .unlimited,
            );

            var lines = std.mem.splitScalar(u8, content, '\n');

            const line1 = lines.next() orelse continue;
            const line2 = lines.next() orelse continue;

            const combined = try std.mem.concat(allocator, u8, &.{ std.mem.trimEnd(u8, line1, "\r"), " ", std.mem.trimEnd(u8, line2, "\r"), "\n" });

            try files.append(allocator, combined);
            // delete old files
            try dir.deleteFile(init.io, entry.path);
        }
    } else {
        std.log.warn(pendingChangelogDir ++ "does not exist\n", .{});
    }

    return try files.toOwnedSlice(allocator);
}

fn writeToChangelogFile(init: std.process.Init, new_content: [][]const u8) !void {
    const allocator = init.arena.allocator();

    var output_dir = try std.Io.Dir.cwd().openDir(
        init.io,
        ".",
        .{},
    );
    defer output_dir.close(init.io);

    const existing_content = output_dir.readFileAlloc(
        init.io,
        "CHANGELOG.md",
        allocator,
        .unlimited,
    ) catch |err| switch (err) {
        error.FileNotFound => "",
        else => return err,
    };

    var combined: std.ArrayList(u8) = .empty;

    try combined.appendSlice(allocator, "\n");

    for (new_content) |line| {
        const foramttedLine = try std.mem.concat(allocator, u8, &.{ "- ", line });
        try combined.appendSlice(allocator, foramttedLine);
    }

    try combined.appendSlice(allocator, "\n");
    try combined.appendSlice(allocator, existing_content);

    const result = try combined.toOwnedSlice(allocator);

    const file = try output_dir.createFile(init.io, "CHANGELOG.md", .{});
    defer file.close(init.io);

    var file_writer = file.writer(init.io, &.{});
    const writer = &file_writer.interface;

    _ = try writer.write(result);
    try writer.flush();
}

//TODO(abdemohlbi): needs refactor and cleanup before adding more features
