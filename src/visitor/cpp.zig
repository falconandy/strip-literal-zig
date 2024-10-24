const std = @import("std");
const base = @import("base.zig");
const code = @import("code.zig");
const types = @import("../types.zig");

const cppRawStringPrefixes: []const []const u8 = &.{ "R\"", "LR\"", "u8R\"", "uR\"", "UR\"" };
const cppRawStringPostfixPrefix: []const u8 = ")";
const cppRawStringPostfixPostfix: []const u8 = "\"";

pub const RawStringFactory = struct {
    pub fn bestPrefixLen(next: []const u8) usize {
        var best_prefix_len: ?usize = null;

        for (cppRawStringPrefixes) |prefix| {
            if (std.mem.startsWith(u8, next, prefix)) {
                best_prefix_len = prefix.len;
                break;
            }
        }

        if (best_prefix_len == null) {
            return 0;
        }

        const index = std.mem.indexOfScalar(u8, next, '(');
        return if (index) |idx| idx + 1 else 0;
    }

    pub fn createVisitor(prefix: []const u8) base.Visitor {
        const index = std.mem.indexOfScalar(u8, prefix, '"');
        const postfix = prefix[index.? + 1 .. prefix.len - 1];

        return base.Visitor{
            .string_raw_cpp = RawStringVisitor{
                .postfix = postfix,
            },
        };
    }
};

pub const RawStringVisitor = struct {
    postfix: []const u8,

    pub fn visit(self: RawStringVisitor, next: []const u8) base.VisitResult {
        if (base.findSubData(next, cppRawStringPostfixPrefix, self.postfix, cppRawStringPostfixPostfix)) |index| {
            return base.VisitResult{
                .visitor_changed = true,
                .inner_length = index,
                .postfix_length = self.postfix.len + 2,
            };
        }

        return base.VisitResult{
            .visitor_changed = false,
            .inner_length = next.len,
        };
    }
};
