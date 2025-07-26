const std = @import("std");
const log = std.log;
const assert = std.debug.assert;
const mem = std.mem;
const ArrayList = std.ArrayListUnmanaged;
const Allocator = std.mem.Allocator;
const testing = std.testing;

const lib = @import("lib");
const Signal = lib.types.Signal;
const InputEvent = lib.types.input.InputEvent;
const Stringable = lib.interfaces.Stringable;
const CursorContainer = lib.interfaces.CursorContainer;
const Vec2 = lib.types.Vec2;
const ControlSequence = lib.types.input.ControlSequence;
const intCast = lib.casts.intCast;
const Buffer = lib.types.Buffer;

const TextWindow = @This();

const Error = error{
    NoSequenceValue,
    FailedToRemoveFromBuffer,
};

const new_line_sequence = ControlSequence.new_line.getValue().?;

cursor_position: Vec2,
dimensions: Vec2,
buffer: *Buffer, //one dimensional because of how annoying newlines are
allocator: Allocator,

pub fn init(alloc: Allocator, dimensions: Vec2, buffer: *Buffer) TextWindow {
    return TextWindow{
        .cursor_position = .{ .x = 0, .y = 0 },
        .dimensions = dimensions,
        .buffer = buffer,
        .allocator = alloc,
    };
}

///Adds char to input buffer at cursor position and moves cursor foreward
pub fn addCharToBuffer(self: *TextWindow, char: u8) (Buffer.Error)!void {
    const cursor_position = self.getCursorPositionIndex();
    try self.buffer.appendCharAtPosition(cursor_position, char);
    self.moveCursor(.{ .x = 1, .y = 0 });
}

///Adds sequence text to input buffer at cursor position and moves cursor foreward
pub fn addSequenceToBuffer(self: *TextWindow, sequence: ControlSequence) (Buffer.Error || Error)!void {
    const sequence_text = sequence.getValue() orelse return Error.NoSequenceValue;
    const cursor_position = self.getCursorPositionIndex();
    try self.buffer.appendSliceAtPosition(cursor_position, sequence_text);
    self.moveCursor(Vec2{ .x = intCast(i32, sequence_text.len), .y = 0 });
}

pub fn processEvent(self: *TextWindow, event: InputEvent) (Signal || CursorContainer.Error)!void {
    switch (event) {
        .input => |char| {
            self.addCharToBuffer(char) catch return CursorContainer.Error.FailedToProcessEvent;
            return;
        },
        .control => |sequence| {
            switch (sequence) {
                ControlSequence.new_line => {
                    self.addSequenceToBuffer(sequence) catch |err| {
                        log.err("{any}", .{err});
                        return CursorContainer.Error.FailedToProcessEvent;
                    };
                    self.moveCursor(.{
                        .x = -self.cursor_position.x,
                        .y = 1,
                    });
                },
                ControlSequence.backspace => {
                    self.deleteAtCursorPosition() catch |err| {
                        log.err("{any}", .{err});
                        return CursorContainer.Error.FailedToProcessEvent;
                    };
                },
                .left => {
                    self.moveCursor(.{ .x = -1 });
                },
                .right => {
                    self.moveCursor(.{ .x = 1 });
                },
                .up => {
                    self.moveCursor(.{ .y = -1 });
                },
                .down => {
                    self.moveCursor(.{ .y = 1 });
                },
                else => return,
            }
            return;
        },
    }
}

/// Returns the position of the cursor
fn getCursorPositionIndex(self: TextWindow) usize {
    var line_sep_list = self.buffer.getLineSepperatedList(self.allocator) catch |err| {
        log.err("Could not get line sep list {any}", .{err});
        return self.buffer.data.items.len;
    };
    defer line_sep_list.deinit(self.allocator);

    const col = intCast(usize, self.cursor_position.x);
    const row = intCast(usize, self.cursor_position.y);

    //vertical position check
    assert(line_sep_list.items.len >= row);

    //horizontal position check
    if (line_sep_list.items.len > 0) assert(line_sep_list.items[row].len >= col);

    var index: usize = 0;
    for (0..row) |r| {
        index += line_sep_list.items[r].len;
        index += new_line_sequence.len;
    }

    index += col;

    return index;
}

/// From an index within text_buffer returns the cursor position.
fn getCursorPositionFromIndex(self: TextWindow, index: usize) !Vec2 {
    assert(self.buffer.data.items.len >= index);

    var position = Vec2.ZERO;

    var line_sep_list = try self.buffer.getLineSepperatedList(self.allocator);
    defer line_sep_list.deinit(self.allocator);

    var current_index: usize = 0;
    for (line_sep_list.items, 0..) |line, line_index| {
        const final_line_index = current_index + line.len + new_line_sequence.len;

        if (final_line_index <= index and line_index != line_sep_list.items.len - 1) {
            current_index = final_line_index;
            position.y += 1;
            continue;
        }

        position.x += intCast(i32, index - current_index);

        break;
    }
    return position;
}

pub fn moveCursor(self: *TextWindow, offset: Vec2) void {
    var line_sep_list = self.buffer.getLineSepperatedList(self.allocator) catch |err| {
        log.err("Could not get line sep list {any}", .{err});
        return;
    };
    defer line_sep_list.deinit(self.allocator);

    const text_row_count = intCast(i32, line_sep_list.items.len);

    const largest_y_position = @max(0, text_row_count - 1);

    const next_y_position = std.math.clamp(
        self.cursor_position.y + offset.y,
        0,
        largest_y_position,
    );

    const next_col_count: i32 = if (line_sep_list.items.len > 0)
        intCast(
            i32,
            line_sep_list.items[intCast(usize, next_y_position)].len,
        )
    else
        0;

    const largest_x_position = next_col_count;

    const next_x_position = std.math.clamp(
        self.cursor_position.x + offset.x,
        0,
        largest_x_position,
    );

    self.cursor_position = .{ .x = next_x_position, .y = next_y_position };
}

pub fn deleteAtCursorPosition(self: *TextWindow) Error!void {
    var cursor_index = self.getCursorPositionIndex();

    //at beginning of file
    if (cursor_index == 0) return;

    //delete new line
    if (self.cursor_position.x == 0 and self.cursor_position.y != 0) {
        for (0..new_line_sequence.len) |_| {
            _ = self.buffer.data.orderedRemove(cursor_index - 1);
            cursor_index -= 1;
        }
        self.cursor_position = self.getCursorPositionFromIndex(cursor_index) catch
            return Error.FailedToRemoveFromBuffer;
        return;
    }

    //regular char delete
    _ = self.buffer.data.orderedRemove(cursor_index - 1);
    self.moveCursor(.{ .x = -1, .y = 0 });
}

fn getLineAtRow(self: *TextWindow, row: i32) []const u8 {
    const row_count = mem.count(u8, self.buffer.data.items, new_line_sequence) + 1;

    var line_iter = mem.splitSequence(u8, self.buffer.data.items, new_line_sequence);
    std.debug.assert(row <= row_count);
    for (0..row_count) |curr_row| {
        const line = line_iter.next();
        if (intCast(i32, curr_row) == row) {
            return line.?;
        }
    }
    unreachable;
}

/// Returns the positon of the cursor in screen space
fn getCursorViewPosition(self: TextWindow) Vec2 {
    const view_bound: Vec2 = .{
        .x = @divTrunc(self.cursor_position.x, self.dimensions.x) * self.dimensions.x,
        .y = @divTrunc(self.cursor_position.y, self.dimensions.y) * self.dimensions.y,
    };

    const screen_space_position = self.cursor_position.sub(view_bound);
    return screen_space_position;
}

pub inline fn stringable(self: *TextWindow) Stringable {
    return Stringable.from(self);
}

pub fn toStringList(self: *TextWindow, alloc: Allocator) Allocator.Error!ArrayList(ArrayList(u8)) {
    var output_list = try ArrayList(ArrayList(u8)).initCapacity(
        alloc,
        intCast(usize, self.dimensions.y),
    );

    var line_sep_list = try self.buffer.getLineSepperatedList(self.allocator);
    defer line_sep_list.deinit(self.allocator);

    const lower_bound = self.getLowerViewBound();
    const upper_bound = lower_bound.add(self.dimensions);

    for (intCast(usize, lower_bound.y)..intCast(usize, upper_bound.y)) |row_num| {
        if (line_sep_list.items.len <= row_num) break;

        var line = line_sep_list.items[row_num];

        //Line is empty in view but between filled lines
        if (line.len <= intCast(usize, lower_bound.x)) {
            output_list.appendAssumeCapacity(.empty);
            continue;
        }

        const adjusted_line_len: usize = @min(line.len, intCast(usize, upper_bound.x));
        line = line[intCast(usize, lower_bound.x)..adjusted_line_len];

        var line_list = try ArrayList(u8).initCapacity(alloc, line.len);
        line_list.appendSliceAssumeCapacity(line);
        output_list.appendAssumeCapacity(line_list);
    }

    return output_list;
}

fn getLowerViewBound(self: *TextWindow) Vec2 {
    // 0 is the first segment, 1 is the second and so on
    const view_segment: Vec2 = .{
        .x = @divTrunc(self.cursor_position.x, self.dimensions.x),
        .y = @divTrunc(self.cursor_position.y, self.dimensions.y),
    };

    return Vec2{
        .x = self.dimensions.x * view_segment.x,
        .y = self.dimensions.y * view_segment.y,
    };
}

inline fn getViewIndex(char_pos: Vec2, lower_bound: Vec2, dimensions: Vec2) usize {
    return intCast(
        usize,
        (char_pos.y - lower_bound.y) * dimensions.x + (char_pos.x - lower_bound.x),
    );
}

pub inline fn cursorContainer(self: *TextWindow) CursorContainer {
    return CursorContainer.from(self);
}

pub inline fn getCursorPosition(self: *TextWindow) Vec2 {
    return self.getCursorViewPosition();
}

test "MemTest" {
    const alloc = std.testing.allocator;
    var buffer = Buffer.init(alloc);
    var t = TextWindow.init(alloc, Vec2{ .x = 100, .y = 100 }, &buffer);
    defer buffer.deinit();
    try t.addCharToBuffer('3');
    try t.addSequenceToBuffer(.new_line);
}

test "get cursor index" {
    const alloc = std.testing.allocator;
    var buffer = Buffer.init(alloc);
    var t = TextWindow.init(alloc, Vec2{ .x = 100, .y = 100 }, &buffer);

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
    try testing.expectEqual(2, t.getCursorPositionIndex());

    buffer.deinit();
}

test "inserting" {
    const alloc = std.testing.allocator;
    var buffer = Buffer.init(alloc);
    var t = TextWindow.init(alloc, Vec2{ .x = 100, .y = 100 }, &buffer);
    defer buffer.deinit();

    try t.addCharToBuffer('1');

    try t.addSequenceToBuffer(.new_line);
    t.moveCursor(.{ .x = 0, .y = 1 });
    t.cursor_position.x = 0;

    try t.addCharToBuffer('2');

    try t.addSequenceToBuffer(.new_line);
    t.moveCursor(.{ .x = 0, .y = 1 });
    t.cursor_position.x = 0;

    try testing.expectEqualStrings("1\n2\n", t.buffer.data.items);
}

test "line sepperation" {
    const alloc = std.testing.allocator;
    var buffer = Buffer.init(alloc);
    var t = TextWindow.init(alloc, Vec2{ .x = 100, .y = 100 }, &buffer);
    defer buffer.deinit();

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

    var line_sep_list = try t.buffer.getLineSepperatedList(alloc);
    defer line_sep_list.deinit(t.allocator);

    //line count
    try testing.expectEqual(3, line_sep_list.items.len);

    //line char count
    try testing.expectEqual(1, line_sep_list.items[0].len);
    try testing.expectEqual(1, line_sep_list.items[1].len);
    try testing.expectEqual(2, line_sep_list.items[2].len);

    //content check
    try testing.expectEqualStrings("1", line_sep_list.items[0]);
    try testing.expectEqualStrings("2", line_sep_list.items[1]);
    try testing.expectEqualStrings("34", line_sep_list.items[2]);
}

test "line peek" {
    const alloc = std.testing.allocator;
    var buffer = Buffer.init(alloc);
    var t = TextWindow.init(alloc, Vec2{ .x = 100, .y = 100 }, &buffer);
    defer buffer.deinit();

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
    const alloc = std.testing.allocator;
    var buffer = Buffer.init(alloc);
    var t = TextWindow.init(alloc, Vec2{ .x = 100, .y = 100 }, &buffer);
    defer buffer.deinit();

    try t.addCharToBuffer('1');

    try t.addSequenceToBuffer(.new_line);
    t.moveCursor(.{ .x = 0, .y = 1 });
    t.cursor_position.x = 0;

    try t.addCharToBuffer('2');
    try t.addCharToBuffer('3');

    //content check
    try testing.expectEqualStrings("1", t.getLineAtRow(0));
    try testing.expectEqualStrings("23", t.getLineAtRow(1));

    try t.deleteAtCursorPosition();

    try testing.expectEqualStrings("2", t.getLineAtRow(1));
    try testing.expectEqual(1, t.getLineAtRow(1).len);

    try t.deleteAtCursorPosition();
    try t.deleteAtCursorPosition();
    try testing.expectEqualDeep(Vec2{ .x = 1, .y = 0 }, t.cursor_position);
}

test "Cursor Postion Index" {
    const alloc = std.testing.allocator;
    var buffer = Buffer.init(alloc);
    var t = TextWindow.init(alloc, Vec2{ .x = 100, .y = 100 }, &buffer);
    defer buffer.deinit();

    try t.buffer.data.appendSlice(alloc, "abcde" ++ new_line_sequence);
    try t.buffer.data.appendSlice(alloc, "fg" ++ new_line_sequence);
    try t.buffer.data.appendSlice(alloc, new_line_sequence);
    try t.buffer.data.appendSlice(alloc, "hijk" ++ new_line_sequence);
    try t.buffer.data.appendSlice(alloc, "lm");

    t.cursor_position = Vec2.ZERO;
    var position = try t.getCursorPositionFromIndex(t.getCursorPositionIndex());
    try testing.expectEqualDeep(t.cursor_position, position);

    t.cursor_position = .{ .x = 0, .y = 1 };
    position = try t.getCursorPositionFromIndex(t.getCursorPositionIndex());
    try testing.expectEqualDeep(t.cursor_position, position);

    t.cursor_position = .{ .x = 2, .y = 0 };
    position = try t.getCursorPositionFromIndex(t.getCursorPositionIndex());
    try testing.expectEqualDeep(t.cursor_position, position);

    t.cursor_position = .{ .x = 1, .y = 4 };
    position = try t.getCursorPositionFromIndex(t.getCursorPositionIndex());
    try testing.expectEqualDeep(t.cursor_position, position);

    t.cursor_position = .{ .x = 0, .y = 2 };
    position = try t.getCursorPositionFromIndex(t.getCursorPositionIndex());
    try testing.expectEqualDeep(t.cursor_position, position);
}
