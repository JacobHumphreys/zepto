const TextWindow = @import("App/output/TextWindow.zig");
const Outputter = @import("App/Outputter.zig");


//This is here because zig would not test my files the correct way when using normal building
test "Run All Tests" {
    _ = Outputter;
    _ = TextWindow;
}
