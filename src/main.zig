const std = @import("std");
const Io = std.Io;

const maintainer = @import("maintainer");
const command = @import("command.zig");

pub fn main(init: std.process.Init) !void {
    std.log.info("Welcome to Maintainer\n", .{});

    // This is appropriate for anything that lives as long as the process.
    const arena: std.mem.Allocator = init.arena.allocator();

    // Accessing command line arguments:
    const args = try init.minimal.args.toSlice(arena);
    switch (args.len) {
        1 => std.log.warn("You have not choosen any command", .{}),
        // support at most 7 arguments (with the first being the exceutable name)
        2...8 => blk: {
            const validComment = command.commands.get(args[1]);
            if (validComment) |rawCommand| {
                try rawCommand.run(init, args);
                break :blk;
            } else {
                std.log.err("Sorry, not a valid argument", .{});
            }
        },
        else => std.log.warn("Sorry, the maximun allowed number of arguments is 7", .{}),
    }
}
