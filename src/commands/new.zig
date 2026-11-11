const std = @import("std");
const mem = @import("std").mem;
const Command = @import("../command.zig").Command;

pub const pendingChangelogDir = "pending_changelogs";
pub const new = .{
    "new",
    Command{ .version = "0.0.1", .help = "create a new random .yml file inside " ++ pendingChangelogDir ++ " dir, which will be created if it does not exist.\n" ++ "-r option can be used as follows" ++ "new -r \"changelog entry\" \"PR link\"\n", .run = newCommand },
};

pub fn newCommand(init: std.process.Init, args: []const [:0]const u8) !void {
    // meaning that it was invoked by ./Maintainer new
    if (args.len == 2) {
        try createRandomFile(init);
        return;
    }

    if (mem.eql(u8, args[2], "-r")) {
        if (args.len == 5) {
            try createRandomFileAndInsertContent(init, args[3], args[4]);
            //TODO(abdemohlbi): add small checks to check for arguments format
            return;
        } else {
            std.log.warn("wrong usage -r option of the new command should be used as follows:\n" ++ "./Maintainer new -r \"changelog entry\" \"PR link\"\n", .{});
            return;
        }
    }

    // if the first argument is --help
    if (mem.eql(u8, args[2], "--help")) {
        std.log.info("{s}\n", .{new.@"1".help});
        return;
    }
    // if the first argument is --version
    if (mem.eql(u8, args[2], "--version")) {
        std.log.info("new command version {s}\n", .{new.@"1".version});
        return;
    }
}

pub fn createRandomFile(init: std.process.Init) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const rng_impl: std.Random.IoSource = .{ .io = init.io };
    const secureRand = rng_impl.interface();
    const randomNum = secureRand.int(u8);

    var buf1: [10]u8 = undefined;
    const currentTimeStamp = std.Io.Clock.real.now(init.io);
    const currentTimeStampString = try std.fmt.bufPrint(&buf1, "{}", .{currentTimeStamp.toSeconds()});

    var buf: [8]u8 = undefined;
    const numAsString = try std.fmt.bufPrint(&buf, "{}", .{randomNum});

    // concact current clock time in seconds with a random 8 bit number
    const fileName = try std.mem.concat(arena, u8, &[_][]const u8{ currentTimeStampString, numAsString, ".yml" });

    // create the pending_changelogs dir if it does not exist aready
    //TODO(abdemohlbi): found this on github not sure how this works @fromBackingInt(@intCast(0o700))
    const dirStatus = try std.Io.Dir.cwd().createDirPathStatus(init.io, pendingChangelogDir, @fromBackingInt(@intCast(0o700)));
    if (dirStatus == .created) {
        std.log.info(pendingChangelogDir ++ " dir did not exist before. creating...\n", .{});
    }

    var changelog_dir = try std.Io.Dir.cwd().openDir(init.io, pendingChangelogDir, .{});
    defer changelog_dir.close(init.io);

    _ = try changelog_dir.createFile(init.io, fileName, .{});
    std.log.info("created {s} successfully\n", .{fileName});
}

pub fn createRandomFileAndInsertContent(init: std.process.Init, description: []const u8, prLink: []const u8) !void {
    const arena: std.mem.Allocator = init.arena.allocator();
    const rng_impl: std.Random.IoSource = .{ .io = init.io };
    const secureRand = rng_impl.interface();
    const randomNum = secureRand.int(u8);

    var buf1: [10]u8 = undefined;
    const currentTimeStamp = std.Io.Clock.real.now(init.io);
    const currentTimeStampString = try std.fmt.bufPrint(&buf1, "{}", .{currentTimeStamp.toSeconds()});

    var buf: [8]u8 = undefined;
    const numAsString = try std.fmt.bufPrint(&buf, "{}", .{randomNum});

    // concact current clock time in seconds with a random 8 bit number
    const fileName = try std.mem.concat(arena, u8, &[_][]const u8{ currentTimeStampString, numAsString, ".yml" });

    // create the pending_changelogs dir if it does not exist aready
    //TODO(abdemohlbi): found this on github not sure how this works @fromBackingInt(@intCast(0o700))
    const dirStatus = try std.Io.Dir.cwd().createDirPathStatus(init.io, pendingChangelogDir, @fromBackingInt(@intCast(0o700)));
    if (dirStatus == .created) {
        std.log.info(pendingChangelogDir ++ " dir did not exist before. creating...\n", .{});
    }

    var changelog_dir = try std.Io.Dir.cwd().openDir(init.io, pendingChangelogDir, .{});
    defer changelog_dir.close(init.io);

    _ = try changelog_dir.createFile(init.io, fileName, .{});
    std.log.info("created {s} successfully\n", .{fileName});

    var combined: std.ArrayList(u8) = .empty;

    const allocator = init.arena.allocator();

    try combined.appendSlice(allocator, description);

    try combined.appendSlice(allocator, "\n");
    try combined.appendSlice(allocator, prLink);

    const result = try combined.toOwnedSlice(allocator);

    const file: std.Io.File = try changelog_dir.createFile(init.io, fileName, .{});
    defer file.close(init.io);

    var file_writer = file.writer(init.io, &.{});
    const writer = &file_writer.interface;

    _ = try writer.write(result);
    try writer.flush();
    std.log.info("wrote content to {s} successfully\n", .{fileName});
}

//TODO(abdemohlbi): needs refactor and cleanup before adding more features
