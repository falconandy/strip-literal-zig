const comment = @import("../visitor/comment.zig");
const code = @import("../visitor/code.zig");
const base = @import("../visitor/base.zig");
const string = @import("../visitor/string.zig");
const types = @import("../types.zig");
const swift = @import("../visitor/swift.zig");
const regexp = @import("../visitor/regexp.zig");

pub fn factories() []const base.Factory {
    return &.{
        base.Factory{ .string_swift = swift.StringFactory{} },
        base.Factory{ .regexp = regexp.Factory{} },
        base.Factory{ .comment_single_line = comment.SingleLineFactory{ .prefix = "//" } },
        base.Factory{ .comment_multi_line = comment.MultiLineFactory{ .prefix = "/*", .postfix = "*/", .supports_nesting = true } },
    };
}
