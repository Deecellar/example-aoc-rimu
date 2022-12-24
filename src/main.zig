const std = @import("std");
const solutions = @import("solutions");

pub fn main() !void {
    inline for(@typeInfo(solutions).Struct.decls) |declaration| {
        if(comptime std.meta.trait.hasFunctions(@field(solutions, declaration.name), .{"firstSolution", "secondSolution"})) {
            @call(.auto, @field(@field(solutions, declaration.name), "firstSolution"), .{});
            @call(.auto, @field(@field(solutions, declaration.name), "secondSolution"), .{});
        }
    }
}
