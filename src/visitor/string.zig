const std = @import("std");
const base = @import("base.zig");
const code = @import("code.zig");
const types = @import("../types.zig");

pub const Factory = struct {
    definitions: []const types.StringDefinition,

    pub fn bestPrefixLen(self: Factory, next: []const u8) usize {
        var best_prefix_len: usize = 0;

        for (self.definitions) |definition| {
            for (definition.prefixes) |prefix| {
                if (std.mem.startsWith(u8, next, prefix) and best_prefix_len < prefix.len) {
                    best_prefix_len = prefix.len;
                }
            }
        }

        return best_prefix_len;
    }

    pub fn createVisitor(self: Factory, prefix: []const u8) base.Visitor {
        const definition = self.findDefinition(prefix);

        return base.Visitor{
            .string = Visitor{
                .definition = definition,
            },
        };
    }

    fn findDefinition(self: Factory, prefix: []const u8) types.StringDefinition {
        for (self.definitions) |definition| {
            for (definition.prefixes) |p| {
                if (std.mem.eql(u8, prefix, p)) {
                    return definition;
                }
            }
        }

        return undefined;
    }
};

pub const Visitor = struct {
    definition: types.StringDefinition,
    pending_prefix: ?[]const u8 = null,

    pub fn visit(self: *Visitor, next: []const u8, factories: []const base.Factory) base.VisitResult {
        if (self.pending_prefix) |pp| {
            const pending_prefix = pp;
            self.pending_prefix = null;

            if (std.mem.startsWith(u8, next, pp)) {
                return base.VisitResult{
                    .visitor_changed = false,
                    .prefix_length = pending_prefix.len,
                };
            }
        }

        if (self.definition.skip) |skips| {
            for (skips) |skip| {
                if (std.mem.startsWith(u8, next, skip)) {
                    return base.VisitResult{
                        .visitor_changed = false,
                        .inner_length = skip.len,
                    };
                }
            }
        }

        if (!self.definition.multiline) {
            if (next[0] == '\n' or next[0] == '\r') {
                return base.VisitResult{
                    .visitor_changed = true,
                };
            }
        }

        if (self.definition.postfix) |postfix| {
            if (std.mem.startsWith(u8, next, postfix)) {
                return base.VisitResult{
                    .visitor_changed = true,
                    .postfix_length = postfix.len,
                };
            }
        }

        if (self.definition.template_prefix) |template_prefix| {
            if (std.mem.startsWith(u8, next, template_prefix)) {
                self.pending_prefix = self.definition.template_postfix;

                return base.VisitResult{
                    .visitor_changed = true,
                    .visitor = base.Visitor{ .code = code.Visitor{
                        .factories = factories,
                        .template_postfix = self.definition.template_postfix,
                    } },
                    .postfix_length = template_prefix.len,
                };
            }
        }

        return base.VisitResult{
            .visitor_changed = false,
            .inner_length = 1,
        };
    }
};
