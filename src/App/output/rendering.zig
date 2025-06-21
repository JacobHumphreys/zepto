const std = @import("std");
const io = std.io;
const control_code = std.ascii.control_code;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const RenderElement = @import("RenderElement.zig");

const lib = @import("lib");
const Renderable = lib.Renderable;
const Vec2 = lib.Vec2;
const ControlSequence = lib.input.ControlSequence;

pub const Error = error{
    FailedToClearScreen,
    FailedToMoveCursor,
    FailedToWriteOutput,
};

var std_out: File = io.getStdOut();

///Causes full page redraw line by line. ReRenders text and cursor
pub fn reRenderOutput(elements: []RenderElement, alloc: Allocator) Error!void {
    try clearScreen();

    for (elements, 0..) |element, i| {
        if (!element.is_visible) continue;
        try renderCursorFromGlobalSpace(element.position);
        const element_output = element.value.toString(alloc) catch {
            return Error.FailedToWriteOutput;
        };

        std_out.writer().print("{s}", .{element_output}) catch {
            return Error.FailedToWriteOutput;
        };
        alloc.free(element_output);
        if (i < elements.len - 1) {
            std_out.writer().print("\n", .{}) catch {
                return Error.FailedToWriteOutput;
            };
        }
    }
}

///Uses terminal codes to set rendered cursor position based on window state
pub fn renderCursorFromGlobalSpace(cursor_position: Vec2) Error!void {
    var write_buf: [16]u8 = undefined;
    const screen_space_position = getScreenSpaceCursorPosition(cursor_position);
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
