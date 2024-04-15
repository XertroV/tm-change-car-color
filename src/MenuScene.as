//                                        V ptr to list              V length and capacity (+0x8)
const string MENU_SCENE_TABLE = "48 8B 05 ?? ?? ?? ?? 48 89 01 8B 05 ?? ?? ?? ?? 89 41 08 48 8B C1 C3";

uint64 g_MenuSceneTablePatternPtr = 0;

uint64 g_MenuSceneTablePtr = 0;

void InitMenuSceneTablePatternPtr() {
    g_MenuSceneTablePatternPtr = Dev::FindPattern(MENU_SCENE_TABLE);
    if (g_MenuSceneTablePatternPtr == 0) throw("Failed to find MenuSceneTable pattern");
    warn("Found menu scene table pattern: " + Text::FormatPointer(g_MenuSceneTablePatternPtr));
    auto offset = Dev::ReadUInt32(g_MenuSceneTablePatternPtr + 3);
    g_MenuSceneTablePtr = g_MenuSceneTablePatternPtr + 7 + offset;
    if (g_MenuSceneTablePtr == 0) throw("Failed to find g_MenuSceneTablePtr");
    trace('Found g_MenuSceneTablePtr: ' + Text::FormatPointer(g_MenuSceneTablePtr));
}

uint64 GetMenuScene() {
    if (g_MenuSceneTablePtr == 0) InitMenuSceneTablePatternPtr();
    auto ptr = Dev::ReadUInt64(g_MenuSceneTablePtr);
    if (ptr == 0) return 0;
    auto len = Dev::ReadUInt32(ptr + 8);
    if (len < 10) return 0;
    return Dev::ReadUInt64(ptr + 0x48);
    // return Dev::ForceCast<ISceneVis@>(Dev_GetArbitraryNodAt(Dev::ReadUInt64(ptr + 0x48))).Get();
}

bool IsInMenu() {
    auto app = GetApp();
    return app.Editor is null && app.CurrentPlayground is null
        && app.LoadProgress.State == NGameLoadProgress::EState::Disabled
        && app.Switcher.ModuleStack.Length == 1
        && cast<CTrackManiaMenus>(app.Switcher.ModuleStack[0]) !is null;
}
