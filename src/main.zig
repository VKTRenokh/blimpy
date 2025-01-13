const std = @import("std");

fn enableRawMode(fd: std.posix.fd_t) !void {
    const state = try std.posix.tcgetattr(fd);
    var raw = state;

    raw.iflag.IGNBRK = false;
    raw.iflag.BRKINT = false;
    raw.iflag.PARMRK = false;
    raw.iflag.ISTRIP = false;
    raw.iflag.INLCR = false;
    raw.iflag.IGNCR = false;
    raw.iflag.ICRNL = false;
    raw.iflag.IXON = false;

    raw.oflag.OPOST = false;

    raw.lflag.ECHO = false;
    raw.lflag.ECHONL = false;
    raw.lflag.ICANON = false;
    raw.lflag.IEXTEN = false;

    raw.cflag.CSIZE = .CS8;
    raw.cflag.PARENB = false;

    raw.cc[@intFromEnum(std.posix.V.MIN)] = 1;
    raw.cc[@intFromEnum(std.posix.V.TIME)] = 0;

    try std.posix.tcsetattr(fd, .FLUSH, raw);
}

fn handleSig(sig: c_int) callconv(.C) void {
    std.debug.print("bye", .{sig});
}

pub fn main() !void {
    const tty = try std.posix.open("/dev/tty", .{ .ACCMODE = .RDWR }, 0);

    try enableRawMode(tty);

    var buffer: [4]u8 = undefined;

    const stdin = std.io.getStdIn();
    const stdout = std.io.getStdOut();

    var sa: std.os.linux.Sigaction = .{
        .handler = .{ .handler = handleSig },
        .mask = std.os.linux.empty_sigset,
        .flags = 0,
    };

    while (true) {
        if (std.os.linux.sigaction(std.os.linux.SIG.INT, &sa, null) != 0) {
            return error.Test;
        }

        try stdout.writeAll("blimpy ");

        _ = try stdin.read(&buffer);
    }
}
