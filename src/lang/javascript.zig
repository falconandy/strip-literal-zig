const comment = @import("../visitor/comment.zig");
const code = @import("../visitor/code.zig");
const base = @import("../visitor/base.zig");
const string = @import("../visitor/string.zig");
const regexp = @import("../visitor/regexp.zig");
const types = @import("../types.zig");

pub fn factories() []const base.Factory {
    const string_defintions = .{
        types.StringDefinition{
            .prefixes = &.{"'"},
            .postfix = "'",
            .skip = &.{ "\\'", "\\\\", "\\\n\r", "\\\r\n", "\\\n", "\\\r" },
        },
        types.StringDefinition{
            .prefixes = &.{"\""},
            .postfix = "\"",
            .skip = &.{ "\\\"", "\\\\", "\\\n\r", "\\\r\n", "\\\n", "\\\r" },
        },
        types.StringDefinition{
            .prefixes = &.{"`"},
            .postfix = "`",
            .skip = &.{ "\\`", "\\u{", "\\$" },
            .multiline = true,
            .template_prefix = "${",
            .template_postfix = "}",
        },
    };

    return &.{
        base.Factory{
            .string = string.Factory{ .definitions = &string_defintions },
        },
        base.Factory{ .regexp = regexp.Factory{} },
        base.Factory{ .comment_single_line = comment.SingleLineFactory{ .prefix = "//" } },
        base.Factory{ .comment_multi_line = comment.MultiLineFactory{ .prefix = "/*", .postfix = "*/", .supports_nesting = false } },
    };
}
