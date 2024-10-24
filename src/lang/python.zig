const comment = @import("../visitor/comment.zig");
const code = @import("../visitor/code.zig");
const base = @import("../visitor/base.zig");
const string = @import("../visitor/string.zig");
const types = @import("../types.zig");

pub fn factories() []const base.Factory {
    const string_defintions = .{
        types.StringDefinition{ .prefixes = &.{ "\"", "u\"", "U\"", "b\"", "B\"" }, .postfix = "\"", .skip = &.{ "\\\"", "\\\\", "\\\n\r", "\\\r\n", "\\\n", "\\\r" } },
        types.StringDefinition{ .prefixes = &.{ "'", "u'", "U'", "b'", "B'" }, .postfix = "'", .skip = &.{ "\\'", "\\\\", "\\\n\r", "\\\r\n", "\\\n", "\\\r" } },
        types.StringDefinition{ .prefixes = &.{ "\"\"\"", "u\"\"\"", "U\"\"\"", "b\"\"\"", "B\"\"\"" }, .postfix = "\"\"\"", .multiline = true },
        types.StringDefinition{ .prefixes = &.{ "'''", "u'''", "U'''", "b'''", "B'''" }, .postfix = "'''", .multiline = true },
        types.StringDefinition{ .prefixes = &.{ "r\"", "R\"", "br\"", "bR\"", "Br\"", "BR\"", "rb\"", "rB\"", "Rb\"", "RB\"" }, .postfix = "\"" },
        types.StringDefinition{ .prefixes = &.{ "r'", "R'", "br'", "bR'", "Br'", "BR'", "rb'", "rB'", "Rb'", "RB'" }, .postfix = "'" },
        types.StringDefinition{ .prefixes = &.{ "r\"\"\"", "R\"\"\"", "br\"\"\"", "bR\"\"\"", "Br\"\"\"", "BR\"\"\"", "rb\"\"\"", "rB\"\"\"", "Rb\"\"\"", "RB\"\"\"" }, .postfix = "\"\"\"", .multiline = true },
        types.StringDefinition{ .prefixes = &.{ "r'''", "R'''", "br'''", "bR'''", "Br'''", "BR'''", "rb'''", "rB'''", "Rb'''", "RB'''" }, .postfix = "'''", .multiline = true },
        types.StringDefinition{ .prefixes = &.{ "f\"", "F\"" }, .postfix = "\"", .skip = &.{ "\\\"", "\\\\", "\\\n\r", "\\\r\n", "\\\n", "\\\r" }, .template_prefix = "{", .template_postfix = "}" },
        types.StringDefinition{ .prefixes = &.{ "f'", "F'" }, .postfix = "'", .skip = &.{ "\\'", "\\\\", "\\\n\r", "\\\r\n", "\\\n", "\\\r" }, .template_prefix = "{", .template_postfix = "}" },
        types.StringDefinition{ .prefixes = &.{ "f\"\"\"", "F\"\"\"" }, .postfix = "\"\"\"", .multiline = true, .template_prefix = "{", .template_postfix = "}" },
        types.StringDefinition{ .prefixes = &.{ "f'''", "F'''" }, .postfix = "'''", .multiline = true, .template_prefix = "{", .template_postfix = "}" },
        types.StringDefinition{ .prefixes = &.{ "fr\"", "fR\"", "Fr\"", "FR\"", "rf\"", "rF\"", "Rf\"", "RF\"" }, .postfix = "\"", .template_prefix = "{", .template_postfix = "}" },
        types.StringDefinition{ .prefixes = &.{ "fr'", "fR'", "Fr'", "FR'", "rf'", "rF'", "Rf'", "RF'" }, .postfix = "'", .template_prefix = "{", .template_postfix = "}" },
        types.StringDefinition{ .prefixes = &.{ "fr\"\"\"", "fR\"\"\"", "Fr\"\"\"", "FR\"\"\"", "rf\"\"\"", "rF\"\"\"", "Rf\"\"\"", "RF\"\"\"" }, .postfix = "\"\"\"", .multiline = true, .template_prefix = "{", .template_postfix = "}" },
        types.StringDefinition{ .prefixes = &.{ "fr'''", "fR'''", "Fr'''", "FR'''", "rf'''", "rF'''", "Rf'''", "RF'''" }, .postfix = "'''", .multiline = true, .template_prefix = "{", .template_postfix = "}" },
    };

    return &.{
        base.Factory{
            .string = string.Factory{ .definitions = &string_defintions },
        },
        base.Factory{ .comment_single_line = comment.SingleLineFactory{ .prefix = "#" } },
    };
}
