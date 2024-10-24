pub const Language = enum(u8) {
    go,
    javascript,
    typescript,
    java,
    kotlin,
    python,
    csharp,
    html,
    css,
    cpp,
    c,
    swift,
};

pub const SegmentType = enum(u8) {
    code,
    string,
    regexp,
    comment_single_line,
    comment_multi_line,
};

pub const Segment = struct {
    type: SegmentType,
    prefix_length: usize,
    inner_length: usize,
    postfix_length: usize,

    pub fn isComment(self: Segment) bool {
        return self.type == .comment_single_line or self.type == .comment_multi_line;
    }

    pub fn isString(self: Segment) bool {
        return self.type == .string;
    }

    pub fn isRegexp(self: Segment) bool {
        return self.type == .regexp;
    }

    pub fn length(self: Segment) usize {
        return self.prefix_length + self.inner_length + self.postfix_length;
    }
};

pub const StringDefinition = struct {
    prefixes: []const []const u8,
    postfix: ?[]const u8,
    skip: ?[]const []const u8 = null,
    multiline: bool = false,
    template_prefix: ?[]const u8 = null,
    template_postfix: ?[]const u8 = null,
};
