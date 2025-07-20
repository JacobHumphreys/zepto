const std = @import("std");
const io = std.io;
const control_code = std.ascii.control_code;
const Allocator = std.mem.Allocator;

const ArenaAllocator = std.heap.ArenaAllocator;

const lib = @import("lib");
const intCast = lib.casts.intCast;
const Vec2 = lib.types.Vec2;
const ControlSequence = lib.types.input.ControlSequence;
const CursorContainer = lib.interfaces.CursorContainer;
const Page = lib.interfaces.Page;
const ArrayList = std.ArrayListUnmanaged;

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
pub fn reRenderOutput(page: Page, alloc: Allocator) (Allocator.Error || Error)!void {
    const screen_buffer_2d = try get2dSceenBuffer(alloc, page);
    defer alloc.free(screen_buffer_2d);

    var print_buffer = try flattenScreenBuffer(alloc, screen_buffer_2d, page);
    defer print_buffer.deinit(alloc);

    std_out.writer().print(
        "{s}{s}{s}",
        .{
            ControlSequence.getValue(.hide_cursor).?,
            ControlSequence.getValue(.clear_screen).?,
            print_buffer.items,
        },
    ) catch {
        return Error.FailedToWriteOutput;
    };
}

fn get2dSceenBuffer(alloc: Allocator, page: Page) Allocator.Error![]ArrayList(u8) {
    const page_dimensions = page.getDimensions();

    var page_elements = try page.getElements(alloc);
    defer page_elements.deinit(alloc);

    var screen_buffer_2d = try alloc.alloc(ArrayList(u8), intCast(usize, page_dimensions.y));
    @memset(screen_buffer_2d, ArrayList(u8).empty);

    for (page_elements.items) |element| {
        var arena = ArenaAllocator.init(alloc);
        defer arena.deinit();
        const arena_alloc = arena.allocator();

        if (!element.is_visible) continue;

        const element_output = try element.stringable.toStringList(arena_alloc);

        for (element_output.items, 0..) |line, line_num| {
            const line_i = line_num + intCast(usize, element.position.y);
            try screen_buffer_2d[line_i].appendSlice(alloc, line.items);
        }
    }
    return screen_buffer_2d;
}

/// "Flattens" the 2d buffer into a singular 1d buffer. Free's buffer2d's items.
fn flattenScreenBuffer(alloc: Allocator, buffer_2d: []ArrayList(u8), page: Page) Allocator.Error!ArrayList(u8) {
    const dimensions = page.getDimensions();

    var print_buffer = try ArrayList(u8).initCapacity(
        alloc,
        intCast(usize, 2 * dimensions.x * dimensions.y),
    );

    for (buffer_2d, 0..) |line, i| {
        defer buffer_2d[i].deinit(alloc);

        //Fills Empty lines
        if (line.items.len == 0) {
            print_buffer.appendNTimesAssumeCapacity(' ', intCast(usize, dimensions.x));
            continue;
        }
        print_buffer.appendSliceAssumeCapacity(line.items);
        
        if (line.items.len < intCast(usize, dimensions.x)) {
            //Pads partially filled lines
            print_buffer.appendNTimesAssumeCapacity(
                ' ',
                intCast(usize, dimensions.x) - line.items.len,
            );
        }
    }
    return print_buffer;
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
