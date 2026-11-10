const std = @import("std");
const mem = @import("std").mem;
const Command = @import("../command.zig").Command;
const commands = @import("../command.zig").commands;
const pendingChangelogDir = @import("new.zig").pendingChangelogDir;

const MaintainerErrorSet = error{
    NotImplemented,
};

pub const release = .{
    "release",
    Command{ .version = "0.0.1", .help = "release a new version", .run = releaseCommand },
};

pub fn releaseCommand(init: std.process.Init, args: []const [:0]const u8) !void {
    _ = init;
    // meaning that it was invoked by ./bin list
    if (args.len == 2) {
        return MaintainerErrorSet.NotImplemented;
        // try releasefn(init);
        // return;
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

fn releasefn(
    init: std.process.Init,
) !void {
    // var i: u10 = 0;
    const changelogDir: ?std.Io.Dir = std.Io.Dir.cwd().openDir(init.io, pendingChangelogDir, .{ .iterate = true }) catch null;
    if (changelogDir) |changeDir| {
        defer changeDir.close(init.io);
        var w1 = try changeDir.walk(init.arena.allocator());
        defer w1.deinit();
        while (try w1.next(init.io)) |_| {}
    } else {
        std.log.warn(pendingChangelogDir ++ " does not exist, ignoring\n", .{});
        return;
    }
}
