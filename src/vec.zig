const std = @import("std");

pub fn Vec(comptime T: type) type {
    return struct {
        const Self = @This();

        allocator: std.mem.Allocator,
        capacity: usize,
        size: usize,
        data: []T,

        fn init(allocator: std.mem.Allocator, capacity: usize) !Self {
            const data: []T = try allocator.alloc(T, capacity);
            errdefer allocator.free(data);

            const instance: Self = .{ .capacity = capacity, .data = data, .allocator = allocator, .size = 0 };
            return instance;
        }

        fn deinit(self: *Self) void {
            self.allocator.free(self.data);
        }

        fn grow(self: *Self, size: usize) !void {
            const new_size = @max(size, self.size);
            const new_data = try self.allocator.realloc(self.data, new_size);

            self.data = new_data;
            self.capacity = new_size;
        }

        fn push(self: *Self, element: T) !void {
            if (self.size >= self.capacity) try self.grow(self.capacity * 2);
            self.data[self.size] = element;
            self.size += 1;
        }

        fn at(self: *Self, index: usize) ?T {
            if (index >= self.size) return null;
            return self.data[index];
        }

        fn isEmpty(self: *Self) bool {
            return self.size == 0;
        }

        fn insert(self: *Self, index: usize, item: T) !void {
            if (index > self.size) return error.IndexOutOfBounds;
            if (self.size >= self.capacity) try self.grow(self.capacity * 2);

            std.mem.copyBackwards(T, self.data[index + 1 .. self.size + 1], self.data[index..self.size]);

            self.data[index] = item;
            self.size += 1;
        }

        fn prepend(self: *Self, item: T) !void {
            try self.insert(0, item);
        }

        fn pop(self: *Self) ?T {
            if (self.size == 0) return null;
            self.size -= 1;
            return self.data[self.size];
        }

        fn delete(self: *Self, index: usize) ?T {
            if (index >= self.size) return null;
            if (self.size == 0) return null;

            const deleted = self.data[index];
            std.mem.copyForwards(T, self.data[index .. self.size - 1], self.data[index + 1 .. self.size]);

            self.size -= 1;
            return deleted;
        }

        fn find(self: *Self, item: T) ?usize {
            for (0..self.size) |idx| {
                if (self.data[idx] == item) return idx;
            }

            return null;
        }

        fn remove(self: *Self, item: T) bool {
            const index = self.find(item);
            if (index == null) return false;

            _ = self.delete(index.?);
            return true;
        }
    };
}

test Vec {
    const allocator = std.testing.allocator;
    var vec = try Vec(usize).init(allocator, 10);
    defer vec.deinit();

    try vec.push(10);
    try vec.push(20);
    try vec.push(30);
    try vec.push(50);
    try vec.insert(3, 40);
    try vec.prepend(0);

    const popped = vec.pop();
    std.debug.print("Popped: {any}\n", .{popped});

    const shifted = vec.delete(0);
    std.debug.print("Shift Delete: {any}\n", .{shifted});

    // _ = vec.delete(1);
    // _ = vec.remove(20);
    const indexOfTwenty = vec.find(20);
    std.debug.print("Index of twenty: {?}\n", .{indexOfTwenty});

    for (0..vec.size + 1) |idx| {
        std.debug.print("Vec[{}]: {any}\n", .{ idx, vec.at(idx) });
    }
}
