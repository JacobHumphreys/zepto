const std = @import("std");
const log = std.log;
const assert = std.debug.assert;
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
const intCast = lib.casts.intCast;

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
    self.moveCursor(Vec2{ .x = intCast(i32, sequence_text.len), .y = 0 });
}

/// Returns the position of the cursor
fn getCursorPositionIndex(self: TextWindow) usize {
    var line_sep_list = self.getLineSepperatedList() catch |err| {
        log.err("Could not get line sep list {any}", .{err});
        return self.text_buffer.items.len;
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

/// Allocates new arraylist using the structs internal allocator of the text buffer's lines,
/// not including line breaks;
fn getLineSepperatedList(self: TextWindow) Allocator.Error!ArrayList([]u8) {
    var line_sep_list: ArrayList([]u8) = .empty;
    var buffer_window = self.text_buffer.items;

    while (mem.indexOf(u8, buffer_window, new_line_sequence)) |new_line_index| {
        try line_sep_list.append(self.allocator, buffer_window[0..new_line_index]);
        buffer_window = buffer_window[new_line_index + new_line_sequence.len ..];
    }

    if (buffer_window.len >= 1) {
        try line_sep_list.append(self.allocator, buffer_window);
    }

    return line_sep_list;
}

pub fn moveCursor(self: *TextWindow, offset: Vec2) void {
    var line_sep_list = self.getLineSepperatedList() catch |err| {
        log.err("Could not get line sep list {any}", .{err});
        return;
    };
    defer line_sep_list.deinit(self.allocator);

    const text_row_count = @max(0, intCast(i32, line_sep_list.items.len) - 1);

    const largest_y_position = text_row_count;

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

pub fn deleteAtCursorPosition(self: *TextWindow) void {
    var cursor_index = self.getCursorPositionIndex();

    //at beginning of file
    if (cursor_index == 0) {
        return;
    }

    //delete new line
    if (self.cursor_position.x == 0 and self.cursor_position.y != 0) {
        const new_line_seq = ControlSequence.new_line.getValue().?;
        const new_x_pos = intCast(i32, self.getLineAtRow(self.cursor_position.y - 1).len);
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

    var line_iter = mem.splitSequence(u8, self.text_buffer.items, new_line_sequence);
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

pub fn toString(self: *TextWindow, alloc: Allocator) Allocator.Error![]const u8 {
    const render_size = intCast(usize, self.dimensions.x * self.dimensions.y);
    const output = try alloc.alloc(u8, render_size);
    @memset(output, ' ');

    // 0 represents the first segment, 1 the second and so on.
    const view_segment: Vec2 = .{
        .x = @divTrunc(self.cursor_position.x, self.dimensions.x),
        .y = @divTrunc(self.cursor_position.y, self.dimensions.y),
    };

    var line_sep_list = try self.getLineSepperatedList();
    defer line_sep_list.deinit(self.allocator);

    const lower_bound = Vec2{
        .x = self.dimensions.x * view_segment.x,
        .y = self.dimensions.y * view_segment.y,
    };
    const upper_bound = lower_bound.add(self.dimensions);

    for (line_sep_list.items, 0..) |line, row_num| {
        //Limits output to only viewable vertical section of text_buffer
        if (row_num < intCast(usize, lower_bound.y)) continue;
        if (row_num >= intCast(usize, upper_bound.y)) break;

        for (line, 0..) |char, col_num| {
            //Limits output to only viewable horizontal section of text_buffer
            if (col_num < intCast(usize, lower_bound.x)) continue;
            if (col_num >= intCast(usize, upper_bound.x)) break;

            const char_pos = Vec2{
                .x = intCast(i32, col_num),
                .y = intCast(i32, row_num),
            };

            const char_index = getViewIndex(char_pos, lower_bound, self.dimensions);
            output[char_index] = char;
        }
    }

    return output;
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

    var line_sep_list = try t.getLineSepperatedList();
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
