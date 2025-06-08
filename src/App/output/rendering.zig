const std = @import("std");
const io = std.io;
const control_code = std.ascii.control_code;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const TextWindow = @import("TextWindow.zig");
const LinedStringBuffer = std.mem.SplitIterator(u8, u8);

const Vec2 = @import("lib").Vec2;

pub const Error = error{
    FailedToClearScreen,
    FailedToMoveCursor,
    FailedToWriteOutput,
};

var std_out: File = io.getStdOut();

pub fn reRenderOutput(window: TextWindow) Error!void {
    try clearScreen();

    var line_split = window.getLineSepperatedIterator();
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
    const screen_space_position = getScreenSpaceCursorPosition(window.cursor_position);
    const cursor_move =
        std.fmt.bufPrint(
            &write_buf,
            "{c}[{};{}H",
            .{ control_code.esc, screen_space_position.y, screen_space_position.x },
        ) catch {
            return Error.FailedToMoveCursor;
        };
    std_out.writer().print("{s}", .{cursor_move}) catch {
        return Error.FailedToWriteOutput;
    };
}

///Internal Cursor Position is stored using array index coordingates this converts it to terminal
///cursor coordinates (1 to window size).
fn getScreenSpaceCursorPosition(internal_position: Vec2) Vec2 {
    var new_position = internal_position;
    new_position.x += 1;
    new_position.y += 1;
    return new_position;
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
