const renderables = @import("App/ui/renderables.zig");
const Ribbon = renderables.Ribbon;
const TextWindow = renderables.TextWindow;
const UIHandler = @import("App/UIHandler.zig");

//This is here because zig would not test my files the correct way when using normal building
test "Run All Tests" {
    _ = UIHandler;
    _ = TextWindow;
    _ = Ribbon;
}
