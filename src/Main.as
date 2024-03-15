void Main(){
    InitMenuSceneTablePatternPtr();
    startnew(CheckPlayerColor).WithRunContext(Meta::RunContext::UpdateSceneEngine);
}

void OnDestroyed() { FreeAllAllocated(); }

void CheckPlayerColor() {
    auto app = cast<CTrackMania>(GetApp());
    CSmArenaClient@ cp;
    CSmPlayer@ player;
    CSceneVehicleVis@ vis;
    CHmsMgrVisDyna@ dynaVisMgr;
    uint visId;
    while (true) {
        @cp = null;
        @player = null;
        @vis = null;
        @dynaVisMgr = null;
        // Dev::Sleep(5);
        yield();
        if (IsInMenu()) {
            RunForMenu();
            continue;
        }
        if (app.CurrentPlayground is null || app.GameScene is null) continue;
        if ((@cp = cast<CSmArenaClient>(app.CurrentPlayground)) is null) continue;
        if (cp.GameTerminals.Length == 0) continue;
        if (cp.GameTerminals[0].ControlledPlayer is null) continue;
        if ((@player = cast<CSmPlayer>(cp.GameTerminals[0].ControlledPlayer)) is null) continue;
        // car color

        visId = 0;
        if ((@vis = VehicleState::GetVis(app.GameScene, player)) !is null) {
            visId = Dev::GetOffsetUint32(vis, 0);
            SetVisColor(vis);
        }

        SetPilotColors(app.GameScene, visId & 0);

    }
}


void SetPilotColors(ISceneVis@ scene, uint visId) {
    CHmsMgrVisDyna@ dynaVisMgr = cast<CHmsMgrVisDyna>(Dev_GetOffsetNodSafe(scene, 0x40));
    // pilot color
    if ((dynaVisMgr) is null) return;
    auto fakeNod2 = Dev_GetOffsetNodSafe(dynaVisMgr, 0x48);
    if (fakeNod2 is null) return;
    auto len = Dev::GetOffsetUint32(dynaVisMgr, 0x50);
    auto cap = Dev::GetOffsetUint32(dynaVisMgr, 0x54);
    if (len > cap) return;
    // trace('len: ' + len + ' cap: ' + cap);
    uint32 offset = 0;
    for (uint i = 0; i < len; i++) {
        // offset = i * 0xF0;
        offset = i * 0x78;
        // trace('trying offset: ' + i + ' (' + Text::Format('%04x', offset) + ')');
        auto vis2 = Dev_GetOffsetNodSafe(fakeNod2, offset + 0x58);
        if (vis2 is null) continue;
        // trace('trying vis2: ' + i + ' (' + Text::Format('%04x', Dev::GetOffsetUint32(vis2, 0)) + ')');
        if (visId > 0 && Dev::GetOffsetUint32(vis2, 0) != visId) continue;
        auto fakeNod3 = Dev_GetOffsetNodSafe(fakeNod2, offset + 0x38); // 0xB0
        if (fakeNod3 is null) continue;
        Dev::SetOffset(fakeNod3, 0x210, S_CarColor);
        @fakeNod3 = null;
        // trace("found vis2: " + i + " (" + Text::Format("%04x", visId) + ") " + Time::Now);
        // break to only set player
        if (visId > 0) break;
        // break;
    }
}

void SetVisColor(CSceneVehicleVis@ vis) {
    // trace('set vis id: ' + Text::Format('%04x', visId) + ' ' + Time::Now);
    auto fakeNod1 = Dev_GetOffsetNodSafe(vis, 0x70);
    if (fakeNod1 is null) return;
    Dev::SetOffset(fakeNod1, 0x210, S_CarColor);
    @fakeNod1 = null;
}


uint countMenu = 0;

void RunForMenu() {
    auto ptr = GetMenuScene();
    if (ptr == 0) return;
    if (countMenu < 10) {
        trace('menu scene: ' + Text::FormatPointer(ptr));
        countMenu++;
    }
    auto scene = Dev::ForceCast<ISceneVis@>(Dev_GetArbitraryNodAt(ptr)).Get();
    if (scene is null) return;
    auto viss = VehicleState::GetAllVis(scene);
    if (countMenu < 10) trace('viss: ' + viss.Length);
    for (uint i = 0; i < viss.Length; i++) {
        SetVisColor(viss[i]);
    }
    SetPilotColors(scene, 0);
}



CMwNod@ Dev_GetOffsetNodSafe(CMwNod@ nod, uint offset) {
    if (nod is null) return null;
    auto ptr = Dev::GetOffsetUint64(nod, offset);
    if (ptr < 0x0FFFFFFFFFF) return null;
    if (ptr > 0x3FFFFFFFFFF) return null;
    return Dev::GetOffsetNod(nod, offset);
}

CMwNod@ Dev_GetOffsetNodSafe(ISceneVis@ nod, uint offset) {
    if (nod is null) return null;
    auto ptr = Dev::GetOffsetUint64(nod, offset);
    if (ptr < 0x0FFFFFFFFFF) return null;
    if (ptr > 0x3FFFFFFFFFF) return null;
    return Dev::GetOffsetNod(nod, offset);
}

CMwNod@ Dev_GetOffsetNodSafe(CSceneVehicleVis@ nod, uint offset) {
    if (nod is null) return null;
    auto ptr = Dev::GetOffsetUint64(nod, offset);
    if (ptr < 0x0FFFFFFFFFF) return null;
    if (ptr > 0x3FFFFFFFFFF) return null;
    return Dev::GetOffsetNod(nod, offset);
}
