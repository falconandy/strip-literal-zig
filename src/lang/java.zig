const comment = @import("../visitor/comment.zig");
const code = @import("../visitor/code.zig");
const base = @import("../visitor/base.zig");
const string = @import("../visitor/string.zig");
const types = @import("../types.zig");

pub fn factories() []const base.Factory {
    const string_defintions = .{
        types.StringDefinition{ .prefixes = &.{"'"}, .postfix = "'", .skip = &.{ "\\'", "\\\\" } },
        types.StringDefinition{ .prefixes = &.{"\""}, .postfix = "\"", .skip = &.{ "\\\"", "\\\\" } },
        types.StringDefinition{ .prefixes = &.{"\"\"\""}, .postfix = "\"\"\"", .skip = &.{ "\\\"", "\\\\" }, .multiline = true },
    };

    return &.{
        base.Factory{
            .string = string.Factory{ .definitions = &string_defintions },
        },
        base.Factory{ .comment_single_line = comment.SingleLineFactory{ .prefix = "//" } },
        base.Factory{ .comment_multi_line = comment.MultiLineFactory{ .prefix = "/*", .postfix = "*/", .supports_nesting = false } },
    };
}
