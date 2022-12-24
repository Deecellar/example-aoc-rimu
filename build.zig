const std = @import("std");

pub fn build(b: *std.build.Builder) void {
    // Standard target options allows the person running `zig build` to choose
    // what target to build for. Here we do not override the defaults, which
    // means any target is allowed, and the default is native. Other options
    // for restricting supported target set are available.
    const target = b.standardTargetOptions(.{});

    // Standard release options allow the person running `zig build` to select
    // between Debug, ReleaseSafe, ReleaseFast, and ReleaseSmall.
    const mode = b.standardReleaseOptions();
    var solution_pkg = discoverSolutions(b, "src/solutions");
    const exe = b.addExecutable("example-aoc-rimu", "src/main.zig");
    exe.setTarget(target);
    exe.addPackage(solution_pkg);
    exe.setBuildMode(mode);
    exe.install();

    const run_cmd = exe.run();
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    const exe_tests = b.addTest("src/main.zig");
    exe_tests.setTarget(target);
    exe_tests.setBuildMode(mode);

    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&exe_tests.step);
}


const ValidExtension = enum { @".zig" };
const package_result_name = "day_pkg.zig";

fn discoverSolutions(builder: *std.build.Builder, path: []const u8) std.build.Pkg {
    const normalized_path = folder_path: {
        var dir_path = if (std.fs.path.isAbsolute(path)) path else std.fs.path.resolve(builder.allocator, &.{ std.process.getCwdAlloc(builder.allocator) catch unreachable, path }) catch @panic("Could not resolve path, Try again or check the path");
        var dir = std.fs.openDirAbsolute(dir_path, .{}) catch |err| {
            if (err == error.FileNotFound) @panic("Directory not found");
            if (err == error.NotDir) @panic("Path needs to direct to a dir");
            @panic(@errorName(err));
        };
        dir.close();
        break :folder_path dir_path;
    };

    var iterable_dir = std.fs.openIterableDirAbsolute(normalized_path, .{}) catch unreachable;
    defer iterable_dir.close();
    var iterator = iterable_dir.iterate();

    var files = std.ArrayList([]const u8).init(builder.allocator);
    defer files.deinit();
    
    var package_file_path = builder.pathJoin(&.{ normalized_path, package_result_name });
    var package_file = std.fs.createFileAbsolute(package_file_path, .{}) catch unreachable;
    var package_writer = package_file.writer();

    // Fun way of getting all the .zig files under a folder
    while (iterator.next() catch unreachable) |entry| {
        if (entry.kind == .File) {
            if (std.meta.stringToEnum(ValidExtension, std.fs.path.extension(entry.name)) != null) {
                if (std.mem.eql(u8, entry.name, package_result_name)) continue;
                files.append(entry.name) catch unreachable;
            }
        }
    }

    // debug items
    for (files.items) |item| {
        package_writer.print("pub const {s} = @import(\"{s}\");\n", .{ item[0..extensionIndex(item)], item }) catch unreachable;
    }
    return .{ .name = "solutions", .source = .{ .path = builder.pathJoin(&.{ normalized_path, package_result_name }) } };
}

pub fn extensionIndex(path: []const u8) usize {
    const filename = std.fs.path.basename(path);
    const index = std.mem.lastIndexOfScalar(u8, filename, '.') orelse path.len;
    return index;
}
