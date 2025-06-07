const std = @import("std");
const io = std.io;
const control_code = std.ascii.control_code;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const TextWindow = @import("TextWindow.zig");
const LinedStringBuffer = std.mem.SplitIterator(u8, u8);

pub const Error = error{
    FailedToClearScreen,
    FailedToMoveCursor,
    FailedToWriteOutput,
};

var std_out: File = io.getStdOut();

pub fn updateOutput(window: TextWindow) Error!void {
    const newChar = window.text_buffer.getLastOrNull() orelse return;
    std_out.writer().print("{c}", .{newChar}) catch {
        return Error.FailedToWriteOutput;
    };
    try renderCursor(window);
}

pub fn reRenderOutput(window: TextWindow) Error!void {
    try clearScreen();

    var line_split = window.getLineSepperatedBuffer();
    while (line_split.next()) |line| {
        std_out.writer().print("{s}", .{line}) catch return Error.FailedToWriteOutput;

        if (line_split.peek() != null) {
            std_out.writer().print("\n", .{}) catch return Error.FailedToWriteOutput;
        }
    }
    try renderCursor(window);
}

pub fn renderCursor(window: TextWindow) Error!void {
    var write_buf: [16]u8 = undefined;
    const cursor_move =
        std.fmt.bufPrint(
            &write_buf,
            "{c}[{};{}H",
            .{ control_code.esc, window.cursor_position.y, window.cursor_position.x },
        ) catch {
            return Error.FailedToMoveCursor;
        };
    std_out.writer().print("{s}", .{cursor_move}) catch {
        return Error.FailedToWriteOutput;
    };
}

pub fn clearScreen() Error!void {
    const clear_screen = [1]u8{control_code.esc} ++ "[2J";
    const move_cursor_to_home = [1]u8{control_code.esc} ++ "[H";
    std_out.writer().print(
        "{s}",
        .{clear_screen ++ move_cursor_to_home},
    ) catch {
        return Error.FailedToClearScreen;
    };
}
