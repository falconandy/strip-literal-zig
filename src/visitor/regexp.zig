const std = @import("std");
const base = @import("base.zig");
const types = @import("../types.zig");

const validPreRegexpChars = &.{ '=', ',', ';', '(', '{', '}' };

pub const Factory = struct {
    pub fn bestPrefixLen(next: []const u8, prev: []const u8) usize {
        if (next[0] != '/') {
            return 0;
        }

        const trimmed_prev = std.mem.trimRight(u8, prev, " \t"); // \f
        if (trimmed_prev.len == 0) {
            return 0;
        }

        const last_prev_char = trimmed_prev[trimmed_prev.len - 1];
        return if (std.mem.indexOfScalar(u8, validPreRegexpChars, last_prev_char)) |_| 1 else 0;
    }

    pub fn createVisitor() base.Visitor {
        return base.Visitor{
            .regexp = Visitor{},
        };
    }
};

pub const Visitor = struct {
    square_bracket_level: i16 = 0,

    pub fn visit(self: *Visitor, next: []const u8) base.VisitResult {
        if (next[0] == '\n' or next[0] == '\r') {
            return base.VisitResult{
                .visitor_changed = true,
            };
        } else if (next.len >= 2 and next[0] == '\\' and next[1] == '/') {
            return base.VisitResult{
                .visitor_changed = false,
                .inner_length = 2,
            };
        } else if (next.len >= 2 and next[0] == '\\' and next[1] == '[') {
            return base.VisitResult{
                .visitor_changed = false,
                .inner_length = 2,
            };
        } else if (next[0] == '[') {
            self.square_bracket_level += 1;
            return base.VisitResult{
                .visitor_changed = false,
                .inner_length = 1,
            };
        } else if (next.len >= 2 and next[0] == '\\' and next[1] == ']') {
            return base.VisitResult{
                .visitor_changed = false,
                .inner_length = 2,
            };
        } else if (next[0] == ']') {
            if (self.square_bracket_level > 0) {
                self.square_bracket_level -= 1;
            }

            return base.VisitResult{
                .visitor_changed = false,
                .inner_length = 1,
            };
        } else if (next[0] == '/' and self.square_bracket_level == 0) {
            var i: u16 = 1;
            while (i < next.len and 'a' <= next[i] and next[i] <= 'z') {
                i += 1;
            }

            return base.VisitResult{
                .visitor_changed = true,
                .postfix_length = i,
            };
        }

        return base.VisitResult{
            .visitor_changed = false,
            .inner_length = 1,
        };
    }
};
