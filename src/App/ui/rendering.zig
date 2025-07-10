const std = @import("std");
const io = std.io;
const assert = std.debug.assert;
const control_code = std.ascii.control_code;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const File = std.fs.File;

const lib = @import("lib");
const intCast = lib.casts.intCast;
const Renderable = lib.interfaces.Renderable;
const Vec2 = lib.types.Vec2;
const ControlSequence = lib.input.ControlSequence;

const RenderElement = @import("RenderElement.zig");

pub const Error = error{
    FailedToClearScreen,
    FailedToMoveCursor,
    FailedToWriteOutput,
};

var std_out: File = io.getStdOut();

///Causes full page redraw line by line. ReRenders text and cursor
pub fn reRenderOutput(elements: []RenderElement, dimensions: Vec2, alloc: Allocator) Error!void {
    try clearScreen();

    const screen_buffer = alloc.alloc(u8, intCast(usize, dimensions.x * dimensions.y)) catch {
        return Error.FailedToWriteOutput;
    };
    defer alloc.free(screen_buffer);
    @memset(screen_buffer, ' ');

    for (elements) |element| {
        if (!element.is_visible) continue;

        const position_index = intCast(
            usize,
            element.position.y * dimensions.x + element.position.x,
        );

        const element_output = element.stringable.toString(alloc) catch {
            return Error.FailedToWriteOutput;
        };
        defer alloc.free(element_output);

        @memcpy(
            screen_buffer[position_index .. position_index + element_output.len],
            element_output,
        );
    }
    std_out.writer().print("{s}", .{screen_buffer}) catch {
        return Error.FailedToWriteOutput;
    };
}

/// Moves cursor to the screen-space position cooresponding to
/// the Global space position provided by the CursorContainer
pub fn renderCursor(current_window: RenderElement) Error!void {
    const cursor_position = current_window.cursorContainer.?.getCursorPosition();
    return renderCursorFromGlobalSpace(
        cursor_position.add(current_window.position),
    );
}

///Uses terminal codes to set rendered cursor position based on window state
fn renderCursorFromGlobalSpace(cursor_position: Vec2) Error!void {
    var write_buf: [32]u8 = undefined;
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
