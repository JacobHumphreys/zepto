const renderables = @import("App/ui/renderables.zig");
const Ribbon = renderables.Ribbon;
const TextWindow = renderables.TextWindow;
const input = @import("App/input.zig");

//This is here because zig would not test my files the correct way when using normal building
test "Run All Tests" {
    _ = TextWindow;
    _ = Ribbon;
    _ = input;
}
