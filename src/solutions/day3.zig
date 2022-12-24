const std = @import("std");
pub fn firstSolution() void {
    std.debug.print("{s}: First Solution has been executed\n", .{@src().file});
}
pub fn secondSolution() void {
    std.debug.print("{s}: Second Solution has been executed\n", .{@src().file});
}
