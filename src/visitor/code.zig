const std = @import("std");
const base = @import("base.zig");

pub const Factory = struct {
    factories: []const base.Factory,

    pub fn init(factories: []const base.Factory) Factory {
        return Factory{ .factories = factories };
    }

    pub fn bestPrefixLen() usize {
        return 0;
    }

    pub fn createVisitor(self: Factory) base.Visitor {
        return base.Visitor{
            .code = Visitor{ .factories = self.factories },
        };
    }
};

const Bracket = enum(u2) {
    square = 0,
    parentheses = 1,
    curly = 2,
};

pub const Visitor = struct {
    factories: []const base.Factory,
    template_postfix: ?[]const u8 = null,
    nested_brackets: std.EnumArray(Bracket, u16) = std.EnumArray(Bracket, u16).initDefault(0, .{}),

    pub fn visit(self: *Visitor, next: []const u8, prev: []const u8) base.VisitResult {
        const best_result = self.findBestFactory(next, prev);
        if (best_result.factory) |factory| {
            return base.VisitResult{
                .visitor_changed = true,
                .visitor = factory.createVisitor(next[0..best_result.prefix_len], next[best_result.prefix_len..]),
                .prefix_length = best_result.prefix_len,
            };
        }

        if (self.template_postfix) |template_postfix| {
            if (std.mem.startsWith(u8, next, template_postfix)) {
                var is_closing_bracket = false;

                if (template_postfix.len == 1) {
                    const index = std.mem.indexOfScalar(u8, "])}", template_postfix[0]);
                    is_closing_bracket = (index == 0 and self.nested_brackets.get(.square) > 0) or (index == 1 and self.nested_brackets.get(.parentheses) > 0) or (index == 2 and self.nested_brackets.get(.curly) > 0);
                }

                if (!is_closing_bracket) {
                    return base.VisitResult{
                        .visitor_changed = true,
                    };
                }
            }
        }

        switch (next[0]) {
            '[' => self.openBracket(.square),
            ']' => self.closeBracket(.square),
            '(' => self.openBracket(.parentheses),
            ')' => self.closeBracket(.parentheses),
            '{' => self.openBracket(.curly),
            '}' => self.closeBracket(.curly),
            else => {},
        }

        return base.VisitResult{
            .visitor_changed = false,
            .inner_length = 1,
        };
    }

    fn findBestFactory(self: Visitor, next: []const u8, prev: []const u8) BestFactoryResult {
        var best_factory: ?base.Factory = null;
        var best_prefix_len: usize = 0;

        for (self.factories) |factory| {
            const prefix_len = factory.bestPrefixLen(next, prev);
            if (prefix_len > best_prefix_len) {
                best_prefix_len = prefix_len;
                best_factory = factory;
            }
        }

        return BestFactoryResult{ .factory = best_factory, .prefix_len = best_prefix_len };
    }

    fn openBracket(self: *Visitor, bracket: Bracket) void {
        self.nested_brackets.set(bracket, self.nested_brackets.get(bracket) + 1);
    }

    fn closeBracket(self: *Visitor, bracket: Bracket) void {
        const value = self.nested_brackets.get(bracket);
        if (value > 0) {
            self.nested_brackets.set(bracket, value - 1);
        }
    }
};

const BestFactoryResult = struct {
    factory: ?base.Factory,
    prefix_len: usize,
};
