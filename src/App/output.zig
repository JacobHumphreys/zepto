const std = @import("std");
const io = std.io;
const ascii = std.ascii;
const Allocator = std.mem.Allocator;
const Signal = @import("signals.zig").Signal;

const ArrayList = std.ArrayListUnmanaged;
const File = std.fs.File;

const OutputRenderer = @This();

pub const Error = error{
    FailedToClearScreen,
    FailedToWriteOutput,
    FailedToAppendToBuffer,
};

const ControlSequence = struct {
    const clear_screen = [1]u8{ascii.control_code.esc} ++ "[2J";
    const move_cursor_to_home = [1]u8{ascii.control_code.esc} ++ "[H";
};

const std_out: File = io.getStdOut();
const std_out_writer = std_out.writer();

var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
const allocator = arena.allocator();

var output_buffer: ArrayList(ArrayList(u8)) = .empty;

pub fn addCharToBuffer(char: u8) Error!void {
    if (output_buffer.items.len == 0) {
        output_buffer.append(allocator, ArrayList(u8).empty) catch {
            return Error.FailedToAppendToBuffer;
        };
    }

    if (char == '\n') {
        output_buffer.append(allocator, ArrayList(u8).empty) catch {
            return Error.FailedToAppendToBuffer;
        };
        return;
    }

    var last_line = &output_buffer.items[output_buffer.items.len - 1];
    last_line.append(allocator, char) catch {
        return Error.FailedToAppendToBuffer;
    };
}

pub fn removeFromEndOfBuffer() void {
    _ = output_buffer.pop();
}

pub fn renderOutput() Error!void {
    try clearScreen();
    for (output_buffer.items, 0..) |line, row| {
        for (line.items) |char| {
            std_out_writer.print("{c}", .{char}) catch {
                return Error.FailedToWriteOutput;
            };
        }
        if (row != output_buffer.items.len - 1) {
            std_out_writer.print("\n", .{}) catch {
                return Error.FailedToWriteOutput;
            };
        }
    }
}

fn clearScreen() Error!void {
    std_out_writer.print(
        "{s}",
        .{ControlSequence.clear_screen ++ ControlSequence.move_cursor_to_home},
    ) catch {
        return Error.FailedToClearScreen;
    };
}
