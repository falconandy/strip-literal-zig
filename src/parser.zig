const std = @import("std");
const types = @import("types.zig");
const visitor = @import("visitor/base.zig");
const base = @import("visitor/base.zig");
const go = @import("lang/go.zig");
const code = @import("visitor/code.zig");

const VisitResult = struct {
    prefix_length: usize = 0,
    inner_length: usize = 0,
    postfix_length: usize = 0,

    pub fn add(self: VisitResult, other: VisitResult) VisitResult {
        return VisitResult{
            .prefix_length = self.prefix_length + other.prefix_length,
            .inner_length = self.inner_length + other.inner_length,
            .postfix_length = self.postfix_length + other.postfix_length,
        };
    }

    pub fn has_data(self: VisitResult) bool {
        return self.prefix_length > 0 or self.inner_length > 0 or self.postfix_length > 0;
    }
};

pub fn parseBytes(allocator: std.mem.Allocator, code_factory: base.Factory, source: []const u8) !std.ArrayList(types.Segment) {
    var segments = std.ArrayList(types.Segment).init(allocator);

    var visitors = std.ArrayList(visitor.Visitor).init(allocator);
    defer visitors.deinit();

    try visitors.append(code_factory.createVisitor("", ""));

    var results = std.ArrayList(VisitResult).init(allocator);
    defer results.deinit();

    try results.append(VisitResult{});

    var position: usize = 0;

    while (position < source.len) {
        const current_visitor = &visitors.items[visitors.items.len - 1];

        const visit_result = current_visitor.visit(source[position..], source[0..position], code_factory.code.factories);

        const visitor_changed = visit_result.visitor_changed;
        const next_visitor = visit_result.visitor;
        var result = VisitResult{
            .prefix_length = visit_result.prefix_length,
            .inner_length = visit_result.inner_length,
            .postfix_length = visit_result.postfix_length,
        };
        position += result.prefix_length + result.inner_length + result.postfix_length;

        if (visitor_changed) {
            if (next_visitor == null) {
                const current_result = results.getLast().add(result);
                if (current_result.has_data()) {
                    try segments.append(types.Segment{
                        .type = current_visitor.segmentType(),
                        .prefix_length = current_result.prefix_length,
                        .inner_length = current_result.inner_length,
                        .postfix_length = current_result.postfix_length,
                    });
                }

                _ = visitors.pop();
                _ = results.pop();
            } else {
                var current_result = results.getLast();
                if (result.prefix_length == 0) {
                    current_result = current_result.add(result);
                    result = VisitResult{};
                }

                if (current_result.has_data()) {
                    try segments.append(types.Segment{
                        .type = current_visitor.segmentType(),
                        .prefix_length = current_result.prefix_length,
                        .inner_length = current_result.inner_length,
                        .postfix_length = current_result.postfix_length,
                    });
                }

                if (next_visitor) |next| {
                    try visitors.append(next);
                }

                _ = results.pop();
                try results.append(VisitResult{});
                try results.append(result);
            }
        } else {
            const last_result = &results.items[results.items.len - 1];
            last_result.* = (last_result.*).add(result);
        }
    }

    while (visitors.items.len > 0) {
        const current_visitor = visitors.pop();
        const result = results.pop();

        if (result.has_data()) {
            try segments.append(types.Segment{
                .type = current_visitor.segmentType(),
                .prefix_length = result.prefix_length,
                .inner_length = result.inner_length,
                .postfix_length = result.postfix_length,
            });
        }
    }

    return segments;
}
