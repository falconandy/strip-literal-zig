const comment = @import("../visitor/comment.zig");
const code = @import("../visitor/code.zig");
const base = @import("../visitor/base.zig");
const string = @import("../visitor/string.zig");
const types = @import("../types.zig");

pub fn factories() []const base.Factory {
    return &.{
        base.Factory{ .comment_multi_line = comment.MultiLineFactory{ .prefix = "<!--", .postfix = "-->", .supports_nesting = false } },
    };
}
