const std = @import("std");
const io = std.io;
const control_code = std.ascii.control_code;
const Allocator = std.mem.Allocator;

const lib = @import("lib");
const intCast = lib.casts.intCast;
const Vec2 = lib.types.Vec2;
const ControlSequence = lib.types.input.ControlSequence;
const CursorContainer = lib.interfaces.CursorContainer;
const Page = lib.interfaces.Page;

const RenderElement = lib.types.RenderElement;

pub const Error = error{
    FailedToClearScreen,
    FailedToMoveCursor,
    FailedToWriteOutput,
    FailedToEnterAltView,
    FailedToExitAltView,
};

var std_out = io.getStdOut();

/// Causes full page redraw line by line. ReRenders text and cursor
pub fn reRenderOutput(page: Page, alloc: Allocator) Error!void {
    const page_dimensions = page.getDimensions();
    const screen_buffer = alloc.alloc(u8, intCast(usize, page_dimensions.x * page_dimensions.y)) catch {
        return Error.FailedToWriteOutput;
    };
    defer alloc.free(screen_buffer);
    @memset(screen_buffer, ' ');

    var page_elements = page.getElements(alloc) catch return Error.FailedToWriteOutput;
    defer page_elements.deinit(alloc);

    for (page_elements.items) |element| {
        if (!element.is_visible) continue;

        const position_index = intCast(
            usize,
            element.position.y * page_dimensions.x + element.position.x,
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
    std_out.writer().print(
        "{s}{s}{s}",
        .{
            ControlSequence.getValue(.hide_cursor).?,
            ControlSequence.getValue(.clear_screen).?,
            screen_buffer,
        },
    ) catch {
        return Error.FailedToWriteOutput;
    };
}

/// Moves cursor to the screen-space position cooresponding to
/// the Global space position provided by the CursorContainer
pub fn renderCursor(cursor_parent: RenderElement) Error!void {
    const cursor_position = cursor_parent.cursor_container.?.getCursorPosition();
    return renderCursorFromGlobalSpace(
        cursor_position.add(cursor_parent.position),
    );
}

/// Uses terminal codes to set rendered cursor position based on window state
fn renderCursorFromGlobalSpace(cursor_position: Vec2) Error!void {
    var write_buf: [32]u8 = undefined;
    const screen_space_position = getScreenSpaceCursorPosition(cursor_position);
    const cursor_move =
        std.fmt.bufPrint(
            &write_buf,
            "{c}[{};{}H{s}",
            .{
                control_code.esc,
                screen_space_position.y,
                screen_space_position.x,
                ControlSequence.getValue(.show_cursor).?,
            },
        ) catch {
            return Error.FailedToMoveCursor;
        };
    std_out.writer().print("{s}", .{cursor_move}) catch {
        return Error.FailedToWriteOutput;
    };
}

/// Internal Cursor Position is stored using array index coordingates this converts it to terminal
/// cursor coordinates (1 to window size).
fn getScreenSpaceCursorPosition(internal_position: Vec2) Vec2 {
    var new_position = internal_position;
    new_position.x += 1;
    new_position.y += 1;
    return new_position;
}

pub fn clearScreen() Error!void {
    const clear_screen = ControlSequence.getValue(.clear_screen).?;
    std_out.writer().print(
        "{s}",
        .{clear_screen},
    ) catch {
        return Error.FailedToClearScreen;
    };
}

pub fn enterAltScreen() !void {
    const enter_screen = ControlSequence.enter_alt_screen.getValue().?;
    std_out.writer().print(
        "{s}",
        .{enter_screen},
    ) catch {
        return Error.FailedToEnterAltView;
    };
}

pub fn exitAltScreen() !void {
    const exit_screen = ControlSequence.exit_alt_screen.getValue().?;
    std_out.writer().print(
        "{s}",
        .{exit_screen},
    ) catch {
        return Error.FailedToExitAltView;
    };
}
