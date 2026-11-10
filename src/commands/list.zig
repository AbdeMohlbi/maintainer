const std = @import("std");
const mem = @import("std").mem;
const Command = @import("../command.zig").Command;
const commands = @import("../command.zig").commands;
const expectEqual = std.testing.expectEqual;

pub const list = .{
    "list",
    Command{ .version = "0.0.1", .help = "list all the avilable commands", .run = listCommand },
};

pub fn listCommand(_: std.process.Init, args: []const [:0]const u8) !void {
    // meaning that it was invoked by ./bin list
    if (args.len == 2) {
        for (commands.keys(), commands.values()) |key, value| {
            std.debug.print("{s}\t{s}\t version:{s}\n", .{ key, value.help, value.version });
        }
        return;
    }
    // if the first argument is --help
    if (std.mem.eql(u8, args[2], "--help")) {
        std.log.info("{s}\n", .{list.@"1".help});
        return;
    }
    // if the first argument is --version
    if (std.mem.eql(u8, args[2], "--version")) {
        std.log.info("list command version {s}\n", .{list.@"1".version});
        return;
    }
}
