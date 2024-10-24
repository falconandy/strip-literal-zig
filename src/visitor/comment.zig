const std = @import("std");
const base = @import("base.zig");
const types = @import("../types.zig");

const newLines = "\n\r";

pub const SingleLineFactory = struct {
    prefix: []const u8,

    pub fn bestPrefixLen(self: SingleLineFactory, next: []const u8) usize {
        if (std.mem.startsWith(u8, next, self.prefix)) {
            return self.prefix.len;
        }

        return 0;
    }

    pub fn createVisitor() base.Visitor {
        return base.Visitor{
            .comment_single_line = SingleLineVisitor{},
        };
    }
};

pub const SingleLineVisitor = struct {
    pub fn visit(next: []const u8) base.VisitResult {
        const new_line_index = std.mem.indexOfAny(u8, next, newLines);
        return base.VisitResult{
            .visitor_changed = true,
            .inner_length = new_line_index orelse next.len,
        };
    }
};

pub const MultiLineFactory = struct {
    prefix: []const u8,
    postfix: []const u8,
    supports_nesting: bool,

    pub fn bestPrefixLen(self: MultiLineFactory, next: []const u8) usize {
        if (std.mem.startsWith(u8, next, self.prefix)) {
            return self.prefix.len;
        }

        return 0;
    }

    pub fn createVisitor(self: MultiLineFactory) base.Visitor {
        return base.Visitor{
            .comment_multi_line = MultiLineVisitor{ .prefix = self.prefix, .postfix = self.postfix, .supports_nesting = self.supports_nesting },
        };
    }
};

pub const MultiLineVisitor = struct {
    prefix: []const u8,
    postfix: []const u8,
    supports_nesting: bool,
    nest_level: i32 = 0,

    pub fn visit(self: *MultiLineVisitor, next: []const u8) base.VisitResult {
        if (std.mem.startsWith(u8, next, self.prefix)) {
            if (self.supports_nesting) {
                self.nest_level += 1;
            }

            return base.VisitResult{
                .visitor_changed = false,
                .inner_length = self.prefix.len,
            };
        } else if (std.mem.startsWith(u8, next, self.postfix)) {
            if (self.nest_level > 0) {
                self.nest_level -= 1;

                return base.VisitResult{
                    .visitor_changed = false,
                    .inner_length = self.postfix.len,
                };
            }

            return base.VisitResult{
                .visitor_changed = true,
                .postfix_length = self.postfix.len,
            };
        } else {
            return base.VisitResult{
                .visitor_changed = false,
                .inner_length = 1,
            };
        }
    }
};
