const std = @import("std");
const unicode = std.unicode;
const parser = @import("parser.zig");
const code = @import("visitor/code.zig");
const base = @import("visitor/base.zig");
const types = @import("types.zig");
const go = @import("lang/go.zig");
const javascript = @import("lang/javascript.zig");
const java = @import("lang/java.zig");
const kotlin = @import("lang/kotlin.zig");
const python = @import("lang/python.zig");
const csharp = @import("lang/csharp.zig");
const html = @import("lang/html.zig");
const css = @import("lang/css.zig");
const cpp = @import("lang/cpp.zig");
const c = @import("lang/c.zig");
const swift = @import("lang/swift.zig");

pub const Mode = enum(u8) { none, remove, byte_to_space, rune_to_space };

pub const Options = struct {
    comments: Mode = .none,
    strings: Mode = .none,
};

pub fn stripLiterals(allocator: std.mem.Allocator, source: []u8, language: types.Language, options: Options) usize {
    if (options.strings == .none and options.comments == .none) {
        return source.len;
    }

    const code_factory = code.Factory.init(switch (language) {
        .go => go.factories(),
        .javascript => javascript.factories(),
        .typescript => javascript.factories(),
        .java => java.factories(),
        .kotlin => kotlin.factories(),
        .python => python.factories(),
        .csharp => csharp.factories(),
        .html => html.factories(),
        .css => css.factories(),
        .cpp => cpp.factories(),
        .c => c.factories(),
        .swift => swift.factories(),
    });

    return strip(allocator, base.Factory{ .code = code_factory }, source, options) catch 0;
}

fn strip(allocator: std.mem.Allocator, code_factory: base.Factory, source: []u8, options: Options) !usize {
    var processed: usize = 0;

    const segments = try parser.parseBytes(allocator, code_factory, source);
    defer segments.deinit();

    var position: usize = 0;
    for (segments.items) |segment| {
        const segment_length = segment.length();

        if (options.comments != .none and segment.isComment()) {
            processed = moveBytes(source, processed, position, segment_length, options.comments);
        } else if (options.strings != .none and segment.isString()) {
            processed = copyBytes(source, processed, position, segment.prefix_length);
            processed = moveBytes(source, processed, position + segment.prefix_length, segment.inner_length, options.strings);
            processed = copyBytes(source, processed, position + segment.prefix_length + segment.inner_length, segment.postfix_length);
        } else if (options.strings != .none and segment.isRegexp()) {
            processed = copyBytes(source, processed, position, segment.prefix_length);
            const prev_processed = processed;

            processed = moveBytes(source, processed, position + segment.prefix_length, segment.inner_length, options.strings);
            if (prev_processed == processed and segment.inner_length > 0) {
                source[processed] = ' ';
                processed += 1;
            }

            processed = copyBytes(source, processed, position + segment.prefix_length + segment.inner_length, segment.postfix_length);
        } else {
            processed = copyBytes(source, processed, position, segment_length);
        }

        position += segment_length;
    }

    return processed;
}

fn copyBytes(data: []u8, processed: usize, from: usize, count: usize) usize {
    std.mem.copyForwards(u8, data[processed..], data[from .. from + count]);
    return processed + count;
}

fn moveBytes(data: []u8, processed: usize, from: usize, count: usize, stripMode: Mode) usize {
    var position = from;
    const till = from + count;
    var updated_processed = processed;

    while (position < till) {
        var size: usize = 1;

        if (data[position] == '\n' or data[position] == '\r') {
            data[updated_processed] = data[position];
            updated_processed += 1;
        } else if (stripMode != .remove) {
            if (stripMode == .rune_to_space) {
                size = unicode.utf8ByteSequenceLength(data[position]) catch 1;
            }

            data[updated_processed] = ' ';
            updated_processed += 1;
        }

        position += size;
    }

    return updated_processed;
}
