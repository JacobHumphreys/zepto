const std = @import("std");
const mem = std.mem;
const Tuple = std.meta.Tuple;
const ArrayList = std.ArrayListUnmanaged;
const ArenaAllocator = std.heap.ArenaAllocator;
const Allocator = std.mem.Allocator;
const testing = std.testing;

const lib = @import("lib");
const Stringable = lib.interfaces.Stringable;
const CursorContainer = lib.interfaces.CursorContainer;
const Vec2 = lib.types.Vec2;
const ControlSequence = lib.input.ControlSequence;

const TextWindow = @This();

pub const Error = error{
    FailedToAppendToBuffer,
    NoSequenceValue,
};

const new_line_sequence = ControlSequence.new_line.getValue().?;

cursor_position: Vec2,
dimensions: Vec2,
text_buffer: ArrayList(u8), //one dimensional because of how annoying newlines are
allocator: Allocator,

pub fn init(alloc: Allocator, dimensions: Vec2) TextWindow {
    return TextWindow{
        .cursor_position = .{ .x = 0, .y = 0 },
        .dimensions = dimensions,
        .text_buffer = .empty,
        .allocator = alloc,
    };
}

pub fn deinit(self: *TextWindow) void {
    self.text_buffer.deinit(self.allocator);
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
        index += new_line_sequence.len;
    }

    index += col;

    return index;
}

/// Allocates new arraylist using the structs internal allocator of the text buffer's lines,
/// not including line breaks;
fn getLineSepperatedList(self: TextWindow) Allocator.Error!ArrayList([]u8) {
    var line_sep_list: ArrayList([]u8) = .empty;
    var buffer_window = self.text_buffer.items;
    while (true) {
        const new_line_index = mem.indexOf(u8, buffer_window, new_line_sequence);

        if (new_line_index == null) {
            try line_sep_list.append(self.allocator, buffer_window);
            break;
        }

        try line_sep_list.append(self.allocator, buffer_window[0..new_line_index.?]);
        buffer_window = buffer_window[new_line_index.? + new_line_sequence.len ..];
    }
    return line_sep_list;
}

fn getLineSepperatedIterator(self: TextWindow) mem.SplitIterator(u8, .sequence) {
    const new_line_seq = ControlSequence.new_line.getValue().?;
    return mem.splitSequence(u8, self.text_buffer.items, new_line_seq);
}

pub fn moveCursor(self: *TextWindow, offset: Vec2) void {
    var line_sep_list = self.getLineSepperatedList() catch |err| {
        std.log.debug("Could not get line sep list {any}", .{err});
        return;
    };
    defer line_sep_list.deinit(self.allocator);

    const text_row_count = @max(0, @as(i32, @intCast(line_sep_list.items.len)) - 1);

    const largest_y_position = @min(text_row_count, self.dimensions.y);

    const next_y_position = std.math.clamp(
        self.cursor_position.y + offset.y,
        0,
        largest_y_position,
    );

    const next_col_count: i32 = @max(
        0,
        @as(i32, @intCast(
            line_sep_list.items[@as(usize, @intCast(next_y_position))].len,
        )),
    );

    const largest_x_position = @min(next_col_count, self.dimensions.x - 1);

    const next_x_position = std.math.clamp(
        self.cursor_position.x + offset.x,
        0,
        largest_x_position,
    );

    self.cursor_position = .{ .x = next_x_position, .y = next_y_position };
}

pub fn deleteAtCursorPosition(self: *TextWindow) void {
    var cursor_index = self.getCursorPositionIndex();

    //at beginning of file
    if (cursor_index == 0) {
        return;
    }

    //delete new line
    if (self.cursor_position.x == 0 and self.cursor_position.y != 0) {
        const new_line_seq = ControlSequence.new_line.getValue().?;
        const new_x_pos = @as(i32, @intCast(self.getLineAtRow(self.cursor_position.y - 1).len));
        for (0..new_line_seq.len) |_| {
            _ = self.text_buffer.orderedRemove(cursor_index - 1);
            self.moveCursor(.{ .x = -1, .y = 0 });
            cursor_index -= 1;
        }
        self.cursor_position.x = new_x_pos;
        return;
    }

    //regular char delete
    _ = self.text_buffer.orderedRemove(cursor_index - 1);
    self.moveCursor(.{ .x = -1, .y = 0 });
}

fn getLineAtRow(self: *TextWindow, row: i32) []const u8 {
    const row_count = mem.count(u8, self.text_buffer.items, new_line_sequence) + 1;

    var line_iter = self.getLineSepperatedIterator();
    std.debug.assert(row <= row_count);
    for (0..row_count) |curr_row| {
        const line = line_iter.next();
        if (@as(i32, @intCast(curr_row)) == row) {
            return line.?;
        }
    }
    unreachable;
}

pub fn stringable(self: *TextWindow) Stringable {
    return Stringable.from(self);
}


pub fn toString(self: *TextWindow, alloc: Allocator) Allocator.Error![]const u8 {
    const output = try alloc.alloc(u8, self.text_buffer.items.len);
    @memcpy(output, self.text_buffer.items);
    return output;
}

pub fn cursorContainer(self: *TextWindow) CursorContainer{
    return CursorContainer.from(self);
}

pub fn getCursorPosition(self: *TextWindow) Vec2 {
    return self.cursor_position;
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

test "line peek" {
    var t = TextWindow.init(std.testing.allocator, Vec2{ .x = 100, .y = 100 });
    defer t.deinit();

    try t.addCharToBuffer('1');

    try t.addSequenceToBuffer(.new_line);
    t.moveCursor(.{ .x = 0, .y = 1 });
    t.cursor_position.x = 0;

    try t.addCharToBuffer('2');
    try t.addCharToBuffer('3');

    const row_0 = t.getLineAtRow(0);
    try testing.expectEqualStrings("1", row_0);
    const row_1 = t.getLineAtRow(1);
    try testing.expectEqualStrings("23", row_1);
}

test "Remove char" {
    var t = TextWindow.init(std.testing.allocator, Vec2{ .x = 100, .y = 100 });
    defer t.deinit();

    try t.addCharToBuffer('1');

    try t.addSequenceToBuffer(.new_line);
    t.moveCursor(.{ .x = 0, .y = 1 });
    t.cursor_position.x = 0;

    try t.addCharToBuffer('2');
    try t.addCharToBuffer('3');

    //content check
    try testing.expectEqualStrings("1", t.getLineAtRow(0));
    try testing.expectEqualStrings("23", t.getLineAtRow(1));

    t.deleteAtCursorPosition();

    try testing.expectEqualStrings("2", t.getLineAtRow(1));
    try testing.expectEqual(1, t.getLineAtRow(1).len);

    t.deleteAtCursorPosition();
    t.deleteAtCursorPosition();
    try testing.expectEqualDeep(Vec2{ .x = 1, .y = 0 }, t.cursor_position);
}
