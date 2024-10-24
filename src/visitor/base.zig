const std = @import("std");
const types = @import("../types.zig");
const comment = @import("comment.zig");
const code = @import("code.zig");
const string = @import("string.zig");
const regexp = @import("regexp.zig");
const cpp = @import("cpp.zig");
const swift = @import("swift.zig");

pub const Visitor = union(enum) {
    code: code.Visitor,
    string: string.Visitor,
    regexp: regexp.Visitor,
    comment_single_line: comment.SingleLineVisitor,
    comment_multi_line: comment.MultiLineVisitor,
    string_raw_cpp: cpp.RawStringVisitor,

    pub fn visit(self: *Visitor, next: []const u8, prev: []const u8, factories: []const Factory) VisitResult {
        return switch (self.*) {
            .code => self.code.visit(next, prev),
            .string => self.string.visit(next, factories),
            .regexp => self.regexp.visit(next),
            .comment_single_line => comment.SingleLineVisitor.visit(next),
            .comment_multi_line => self.comment_multi_line.visit(next),
            .string_raw_cpp => self.string_raw_cpp.visit(next),
        };
    }

    pub fn segmentType(self: Visitor) types.SegmentType {
        return switch (self) {
            .code => .code,
            .string => .string,
            .regexp => .regexp,
            .comment_single_line => .comment_single_line,
            .comment_multi_line => .comment_multi_line,
            .string_raw_cpp => .string,
        };
    }
};

pub const VisitResult = struct {
    visitor_changed: bool,
    visitor: ?Visitor = null,
    prefix_length: usize = 0,
    inner_length: usize = 0,
    postfix_length: usize = 0,
};

pub const Factory = union(enum) {
    code: code.Factory,
    string: string.Factory,
    regexp: regexp.Factory,
    comment_single_line: comment.SingleLineFactory,
    comment_multi_line: comment.MultiLineFactory,
    string_cpp_raw: cpp.RawStringFactory,
    string_swift: swift.StringFactory,

    pub fn createVisitor(self: Factory, prefix: []const u8, next: []const u8) Visitor {
        return switch (self) {
            .code => self.code.createVisitor(),
            .string => self.string.createVisitor(prefix),
            .regexp => regexp.Factory.createVisitor(),
            .comment_single_line => comment.SingleLineFactory.createVisitor(),
            .comment_multi_line => self.comment_multi_line.createVisitor(),
            .string_cpp_raw => cpp.RawStringFactory.createVisitor(prefix),
            .string_swift => swift.StringFactory.createVisitor(prefix, next),
        };
    }

    pub fn bestPrefixLen(self: Factory, next: []const u8, prev: []const u8) usize {
        return switch (self) {
            .code => 0,
            .string => self.string.bestPrefixLen(next),
            .regexp => regexp.Factory.bestPrefixLen(next, prev),
            .comment_single_line => self.comment_single_line.bestPrefixLen(next),
            .comment_multi_line => self.comment_multi_line.bestPrefixLen(next),
            .string_cpp_raw => cpp.RawStringFactory.bestPrefixLen(next),
            .string_swift => swift.StringFactory.bestPrefixLen(next),
        };
    }
};

pub fn findSubData(data: []const u8, prefix: []const u8, inner: []const u8, postfix: []const u8) ?usize {
    var position: usize = 0;
    while (position <= data.len - prefix.len - inner.len - postfix.len) {
        if (std.mem.indexOf(u8, data[position..], prefix)) |prefix_index| {
            if (std.mem.startsWith(u8, data[position + prefix_index + prefix.len ..], inner) and std.mem.startsWith(u8, data[position + prefix_index + prefix.len + inner.len ..], postfix)) {
                return position + prefix_index;
            }

            position += prefix_index + 1;
        } else return null;
    }

    return null;
}
