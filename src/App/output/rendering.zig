const std = @import("std");
const io = std.io;
const ascii = std.ascii;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const TextWindow = @import("TextWindow.zig");
const LinedStringBuffer = std.mem.SplitIterator(u8, u8);

pub const Error = error{
    FailedToClearScreen,
    FailedToWriteOutput,
};

var std_out: File = io.getStdOut();

pub fn updateOutput(window: TextWindow) Error!void {
    const newChar = window.text_buffer.getLastOrNull() orelse return;
    std_out.writer().print("{c}", .{newChar}) catch {
        return Error.FailedToWriteOutput;
    };
}

pub fn reRenderOutput(window: TextWindow) Error!void {
    try clearScreen();

    var lineSplit = window.getLineSepperatedBuffer();
    while (lineSplit.next()) |line| {
        std_out.writer().print("{s}", .{line}) catch return Error.FailedToWriteOutput;

        if (lineSplit.peek() != null) {
            std_out.writer().print("\n", .{}) catch return Error.FailedToWriteOutput;
        }
    }
}

pub fn clearScreen() Error!void {
    const clear_screen = [1]u8{ascii.control_code.esc} ++ "[2J";
    const move_cursor_to_home = [1]u8{ascii.control_code.esc} ++ "[H";
    std_out.writer().print(
        "{s}",
        .{clear_screen ++ move_cursor_to_home},
    ) catch {
        return Error.FailedToClearScreen;
    };
}
