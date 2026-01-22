const std = @import("std");
const Allocator = std.mem.Allocator;

pub const Vec2 = @import("types/Vec2.zig");
pub const Buffer = @import("types/Buffer.zig");
pub const input = @import("types/input.zig");

pub const Signal = error{
    Exit,
    SaveBuffer,
    RedrawBuffer,
    ReadFileContents
};

pub const AppInfo = struct {
    name: ?[]const u8 = null,
    version: ?[]const u8 = null,
    buffer_name: ?[]const u8 = null,
    state: ?[]const u8 = null,
};

pub fn Queue(comptime T: type) type {
    return struct {
        const Item = struct {
            node: std.SinglyLinkedList.Node = .{},
            value: T,
        };

        pub const empty = @This(){
            .list = .{},
        };

        list: std.SinglyLinkedList,

        pub fn enqueue(self: *@This(), alloc: Allocator, value: T) Allocator.Error!void {
            const item = try alloc.create(Item);
            item.* = .{ .value = value };
            self.list.prepend(&item.node);
        }

        pub fn dequeue(self: *@This(), alloc: Allocator) ?T {
            if (self.list.popFirst()) |node_field| {
                const item: *Item = @fieldParentPtr("node", node_field);
                defer alloc.destroy(item);

                return item.value;
            }
            return null;
        }

        pub fn deinit(self: *@This(), alloc: Allocator) void {
            while (self.dequeue(alloc)) |_| {}
        }
    };
}
