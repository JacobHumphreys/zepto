const std = @import("std");
const mem = std.mem;
const Tuple = std.meta.Tuple;
const ArrayList = std.ArrayListUnmanaged;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const testing = std.testing;

const lib = @import("lib");
const Vec2 = lib.Vec2;
const ControlSequence = lib.input.ControlSequence;

const TextWindow = @This();

pub const Error = error{
    FailedToAppendToBuffer,
    NoSequenceValue,
};

var arena: ArenaAllocator = undefined;

text_buffer: ArrayList(u8), //one dimensional because of how annoying newlines are
cursor_position: Vec2,
dimensions: Vec2,
allocator: Allocator,

pub fn init(alloc: Allocator, dimensions: Vec2) TextWindow {
    arena = ArenaAllocator.init(alloc);
    return TextWindow{
        .cursor_position = .{ .x = 0, .y = 0 },
        .dimensions = dimensions,
        .text_buffer = .empty,
        .allocator = arena.allocator(),
    };
}

pub fn deinit(self: *TextWindow) void {
    self.text_buffer.deinit(self.allocator);
    arena.deinit();
}

///Adds char to input buffer at cursor position and moves cursor foreward
pub fn addCharToBuffer(self: *TextWindow, char: u8) Error!void {
    const cursor_position = self.getCursorPositionIndex();
    std.log.info("cursor_position: {}", .{cursor_position});
    self.text_buffer.insert(self.allocator, cursor_position, char) catch {
        return Error.FailedToAppendToBuffer;
    };
    self.moveCursor(.{ .x = 1, .y = 0 });
}

///Adds sequence text to input buffer at cursor position and moves cursor foreward
pub fn addSequenceToBuffer(self: *TextWindow, sequence: ControlSequence) Error!void {
    const sequence_text = sequence.getValue() orelse return Error.NoSequenceValue;
    const cursor_position = self.getCursorPositionIndex();
    self.text_buffer.insertSlice(self.allocator, cursor_position, sequence_text) catch {
        return Error.FailedToAppendToBuffer;
    };
    self.moveCursor(Vec2{ .x = @as(i32, @intCast(sequence_text.len)), .y = 0 });
}

fn getCursorPositionIndex(self: TextWindow) usize {
    var line_sep_list = self.getLineSepperatedList() catch |err| {
        std.log.debug("Could not get line sep list {any}", .{err});
        return self.text_buffer.items.len;
    };
    defer line_sep_list.deinit(self.allocator);

    const col = @as(usize, @intCast(self.cursor_position.x));
    const row = @as(usize, @intCast(self.cursor_position.y));

    //vertical position check
    std.debug.assert(line_sep_list.items.len >= row);

    //horizontal position check
    std.debug.assert(line_sep_list.items[row].len >= col);

    var index: usize = 0;
    for (0..row) |r| {
        index += line_sep_list.items[r].len;
        index += 2; // newline sequence length
    }

    index += col;

    return index;
}

pub fn getLineSepperatedIterator(self: TextWindow) mem.SplitIterator(u8, .sequence) {
    return mem.splitSequence(u8, self.text_buffer.items, "\n");
}

fn getLineSepperatedList(self: TextWindow) !ArrayList([]u8) {
    var line_sep_list: ArrayList([]u8) = .empty;
    var buffer_window = self.text_buffer.items;
    while (true) {
        const nl_index = mem.indexOf(u8, buffer_window, "\r\n");
        if (nl_index == null) {
            try line_sep_list.append(self.allocator, buffer_window);
            break;
        }
        try line_sep_list.append(self.allocator, buffer_window[0..nl_index.?]);
        buffer_window = buffer_window[nl_index.? + 2 ..];
    }
    return line_sep_list;
}

pub fn moveCursor(self: *TextWindow, offset: Vec2) void {
    var line_sep_list = self.getLineSepperatedList() catch |err| {
        std.log.debug("Could not get line sep list {any}", .{err});
        return;
    };
    defer line_sep_list.deinit(self.allocator);

    const largest_y_position = @max(
        0,
        @as(i32, @intCast(line_sep_list.items.len)) - 1,
    );

    const next_y_position = std.math.clamp(
        self.cursor_position.y + offset.y,
        0,
        largest_y_position,
    );

    const largest_x_position = @max(
        0,
        @as(
            i32,
            @intCast(line_sep_list.items[@as(usize, @intCast(next_y_position))].len),
        ),
    );

    const next_x_position = std.math.clamp(
        self.cursor_position.x + offset.x,
        0,
        largest_x_position,
    );

    self.cursor_position = .{ .x = next_x_position, .y = next_y_position };
}

pub fn deleteAtCursorPosition(self: *TextWindow) void {
    _ = self;
}

test "MemTest" {
    var t = TextWindow.init(std.testing.allocator, .{ .x = 100, .y = 100 });
    defer t.deinit();
    try t.addCharToBuffer('3');
    try t.addSequenceToBuffer(.new_line);
}

test "get cursor index" {
    var t = TextWindow.init(std.testing.allocator, Vec2{ .x = 100, .y = 100 });

    //single char insertion
    try testing.expectEqual(0, t.getCursorPositionIndex());
    try t.addCharToBuffer('a');
    try testing.expectEqual(1, t.getCursorPositionIndex());

    //move back one
    t.moveCursor(Vec2{ .x = -1, .y = 0 });

    //cursor move check
    try testing.expectEqualDeep(Vec2{ .x = 0, .y = 0 }, t.cursor_position);

    try testing.expectEqual(0, t.getCursorPositionIndex());
    t.moveCursor(Vec2{ .x = 1, .y = 0 });
    try testing.expectEqual(1, t.getCursorPositionIndex());

    try t.addSequenceToBuffer(.new_line);
    t.moveCursor(Vec2{ .x = 0, .y = 1 });
    try testing.expectEqual(3, t.getCursorPositionIndex());

    t.deinit();
}

test "inserting" {
    var t = TextWindow.init(std.testing.allocator, Vec2{ .x = 100, .y = 100 });
    defer t.deinit();

    try t.addCharToBuffer('1');

    try t.addSequenceToBuffer(.new_line);
    t.moveCursor(.{ .x = 0, .y = 1 });
    t.cursor_position.x = 0;

    try t.addCharToBuffer('2');

    try t.addSequenceToBuffer(.new_line);
    t.moveCursor(.{ .x = 0, .y = 1 });
    t.cursor_position.x = 0;

    try testing.expectEqualStrings("1\r\n2\r\n", t.text_buffer.items);
}

test "line sepperation" {
    var t = TextWindow.init(std.testing.allocator, Vec2{ .x = 100, .y = 100 });
    defer t.deinit();

    try t.addCharToBuffer('1');

    try t.addSequenceToBuffer(.new_line);
    t.moveCursor(.{ .x = 0, .y = 1 });
    t.cursor_position.x = 0;

    try t.addCharToBuffer('2');

    try t.addSequenceToBuffer(.new_line);
    t.moveCursor(.{ .x = 0, .y = 1 });
    t.cursor_position.x = 0;

    try t.addCharToBuffer('3');
    try t.addCharToBuffer('4');

    var line_list = try t.getLineSepperatedList();
    defer line_list.deinit(t.allocator);

    //line count
    try testing.expectEqual(3, line_list.items.len);

    //line char count
    try testing.expectEqual(1, line_list.items[0].len);
    try testing.expectEqual(1, line_list.items[1].len);
    try testing.expectEqual(2, line_list.items[2].len);

    //content check
    try testing.expectEqualStrings("1", line_list.items[0]);
    try testing.expectEqualStrings("2", line_list.items[1]);
    try testing.expectEqualStrings("34", line_list.items[2]);
}
