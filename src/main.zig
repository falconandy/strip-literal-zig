const allocator = @import("std").heap.wasm_allocator;
const strip = @import("strip.zig");
const types = @import("types.zig");

export fn malloc(len: u32) ?[*]const u8 {
    const slice = allocator.alloc(u8, len) catch {
        return null;
    };
    return slice.ptr;
}

export fn free(ptr: [*]u8, len: usize) void {
    allocator.free(ptr[0..len]);
}

const languages: []const types.Language = &.{
    .go,
    .javascript,
    .typescript,
    .java,
    .kotlin,
    .python,
    .csharp,
    .html,
    .css,
    .cpp,
    .c,
    .swift,
};

export fn stripLiterals(ptr: [*]u8, len: usize, language_index: u32, strip_mode: u32) usize {
    const comments_mode: strip.Mode = @enumFromInt(strip_mode % 4);
    const strings_mode: strip.Mode = @enumFromInt((strip_mode / 4) % 4);
    return strip.stripLiterals(
        allocator,
        ptr[0..len],
        languages[@intCast(language_index - 1)],
        .{ .comments = comments_mode, .strings = strings_mode },
    );
}
