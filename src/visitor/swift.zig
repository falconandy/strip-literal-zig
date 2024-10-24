const std = @import("std");
const base = @import("base.zig");
const code = @import("code.zig");
const types = @import("../types.zig");
const string = @import("string.zig");

const swiftTemplatePrefixPrefix: []const u8 = "\\";
const swiftTemplatePrefixPostfix: []const u8 = "(";
const swiftTemplatePostfix: []const u8 = ")";
const swiftSingleLineStringSkip: []const []const u8 = &.{ "\\\"", "\\\\" };
const swiftMultiLineStringSkip: []const []const u8 = &.{ "\\\"", "\\\\", "\\\n\r", "\\\r\n", "\\\n", "\\\r" };

pub const StringFactory = struct {
    pub fn bestPrefixLen(next: []const u8) usize {
        if (next[0] == '"') {
            return if (next.len >= 3 and next[1] == '"' and next[2] == '"') 3 else 1;
        }

        if (next[0] != '#') return 0;

        if (std.mem.indexOfScalar(u8, next, '"')) |index| {
            for (0..index - 1) |i| {
                if (next[i + 1] != '#') return 0;
            }

            return if (index + 2 < next.len and next[index + 1] == '"' and next[index + 2] == '"') return index + 3 else index + 1;
        } else {
            return 0;
        }
    }

    pub fn createVisitor(prefix: []const u8, next: []const u8) base.Visitor {
        const multiline = prefix.len >= 3 and prefix[prefix.len - 1] == '"' and prefix[prefix.len - 2] == '"' and prefix[prefix.len - 3] == '"';
        const skip = if (multiline) swiftMultiLineStringSkip else swiftSingleLineStringSkip;

        var postfix: ?[]const u8 = null;
        var template_prefix: ?[]const u8 = null;

        if (multiline) {
            if (base.findSubData(next, prefix[prefix.len - 3 ..], prefix[0..0], prefix[0 .. prefix.len - 3])) |postfix_index| {
                postfix = next[postfix_index .. postfix_index + prefix.len];
            }
            if (base.findSubData(next, swiftTemplatePrefixPrefix, prefix[0 .. prefix.len - 3], swiftTemplatePrefixPostfix)) |template_prefix_index| {
                template_prefix = next[template_prefix_index .. template_prefix_index + prefix.len - 1];
            }
        } else {
            if (base.findSubData(next, prefix[prefix.len - 1 ..], prefix[0..0], prefix[0 .. prefix.len - 1])) |postfix_index| {
                postfix = next[postfix_index .. postfix_index + prefix.len];
            }
            if (base.findSubData(next, swiftTemplatePrefixPrefix, prefix[0 .. prefix.len - 1], swiftTemplatePrefixPostfix)) |template_prefix_index| {
                template_prefix = next[template_prefix_index .. template_prefix_index + prefix.len + 1];
            }
        }

        return base.Visitor{
            .string = string.Visitor{
                .definition = types.StringDefinition{
                    .prefixes = &.{prefix},
                    .postfix = postfix,
                    .skip = skip,
                    .multiline = multiline,
                    .template_prefix = template_prefix,
                    .template_postfix = swiftTemplatePostfix,
                },
            },
        };
    }
};
