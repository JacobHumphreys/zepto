const std = @import("std");
const io = std.io;
const ascii = std.ascii;
const Allocator = std.mem.Allocator;
const ArenaAllocator = std.heap.ArenaAllocator;

const ArrayList = std.ArrayListUnmanaged;
const File = std.fs.File;
const Writer = std.fs.File.Writer;

pub const Error = error{
    FailedToClearScreen,
    FailedToWriteOutput,
    FailedToAppendToBuffer,
};

const ControlSequence = struct {
    const clear_screen = [1]u8{ascii.control_code.esc} ++ "[2J";
    const move_cursor_to_home = [1]u8{ascii.control_code.esc} ++ "[H";
};

const Renderer = @This();

var arena: ArenaAllocator = undefined;

allocator: Allocator,
std_out: File,
output_buffer: ArrayList(ArrayList(u8)),

pub fn init() Renderer {
    arena = ArenaAllocator.init(std.heap.page_allocator);
    const std_out = io.getStdOut();
    return Renderer{
        .allocator = arena.allocator(),

        .std_out = std_out,

        .output_buffer = .empty,
    };
}

pub fn addCharToBuffer(self: *Renderer, char: u8) Error!void {
    if (self.output_buffer.items.len == 0) {
        self.output_buffer.append(self.allocator, ArrayList(u8).empty) catch {
            return Error.FailedToAppendToBuffer;
        };
    }

    if (char == '\n') {
        self.output_buffer.append(self.allocator, ArrayList(u8).empty) catch {
            return Error.FailedToAppendToBuffer;
        };
        return;
    }

    var last_line = &self.output_buffer.items[self.output_buffer.items.len - 1];
    last_line.append(self.allocator, char) catch {
        return Error.FailedToAppendToBuffer;
    };
}

pub fn removeFromEndOfBuffer(self: *Renderer) void {
    _ = self.output_buffer.pop();
}

pub fn updateOutput(self: *Renderer) Error!void {
    const charToPrint = self.output_buffer.getLast().getLast();
    self.std_out.writer().print("{c}", .{charToPrint}) catch {
        return Error.FailedToWriteOutput;
    };
}

pub fn reRenderOutput(self: *Renderer) Error!void {
    try self.clearScreen();
    for (self.output_buffer.items, 0..) |line, row| {
        for (line.items) |char| {
            self.std_out.writer().print("{c}", .{char}) catch {
                return Error.FailedToWriteOutput;
            };
        }
        if (row != self.output_buffer.items.len - 1) {
            self.std_out.writer().print("\n", .{}) catch {
                return Error.FailedToWriteOutput;
            };
        }
    }
}

fn clearScreen(self: *Renderer) Error!void {
    self.std_out.writer().print(
        "{s}",
        .{ControlSequence.clear_screen ++ ControlSequence.move_cursor_to_home},
    ) catch {
        return Error.FailedToClearScreen;
    };
}

pub fn deinit(self: *Renderer) void {
    _ = self;
    arena.deinit();
}
