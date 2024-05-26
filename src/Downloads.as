const string SourceBaseUrl = "https://assets.xk.io/patched-car-skins/";

bool GameDataFileExists(const string &in path) {
    return IO::FileExists(IO::FromAppFolder("GameData/" + path));
}

void CheckCreateGameDataFolder(const string &in path) {
    auto fullPath = IO::FromAppFolder("GameData/" + path);
    if (!IO::FolderExists(fullPath)) {
        IO::CreateFolder(fullPath);
    }
}

string GetFullGameDataPath(const string &in subPath, const string &in fileName) {
    return IO::FromAppFolder("GameData/" + subPath + "/" + fileName);
}

// call this from Main()
void RefreshAssets() {
    CheckCreateGameDataFolder("Vehicles/Items");
    CheckCreateGameDataFolder("Skins/Models/CarSport");
    AddNonAudioAssetDownloads();
}

void AddNonAudioAssetDownloads() {
    AddArbitraryAssetDownload("Vehicles/Items", "CarDesert.Item.Gbx");
    AddArbitraryAssetDownload("Vehicles/Items", "CarRally.Item.Gbx");
    AddArbitraryAssetDownload("Vehicles/Items", "CarSnow.Item.Gbx");
    AddArbitraryAssetDownload("Skins/Models/CarSport", "Snob.zip");
    AddArbitraryAssetDownload("Skins/Models/CarSport", "Rallb.zip");
    AddArbitraryAssetDownload("Skins/Models/CarSport", "Deserb.zip");
}


class AssetDownload {
    string url;
    string path;
    AssetDownload(const string &in url, const string &in path) {
        this.url = url;
        this.path = path;
        DownloadProgress::Add(1);
    }

    ~AssetDownload() {
        this.DoneCallback();
    }

    bool started;
    bool finished;

    void Start() {
        if (started) return;
        started = true;
        startnew(CoroutineFunc(this.RunDownload));
        trace("Downloading " + this.url + " to " + this.path);
        CheckDestinationDir();
    }

    void CheckDestinationDir() {
        auto parts = this.path.Split("/");
        auto fileName = parts[parts.Length - 1];
        parts.RemoveLast();
        auto dir = string::Join(parts, "/");
        trace("Checking destination dir: " + dir);
        if (!IO::FileExists(dir) && !IO::FolderExists(dir)) {
            // create all directories up to the file, then a directory with the name of the file
            IO::CreateFolder(dir, true);
            trace("Created folder: " + dir);
            // // then remove the folder with the same name as the file (but not parent folders)
            // IO::DeleteFolder(path);
            // trace("Removed folder: " + path);
        }
    }

    void RunDownload() {
        uint failCount = 0;
        while (failCount < 3) {
            Net::HttpRequest@ req = Net::HttpGet(this.url);
            while (!req.Finished()) {
                yield();
            }
            this.finished = true;
            if (req.ResponseCode() == 200) {
                req.SaveToFile(this.path);
                DownloadProgress::Done();
                trace("Downloaded " + this.url + " to " + this.path);
                return;
            } else {
                NotifyWarning("Failed to download " + this.url);
                NotifyWarning("Response code: " + req.ResponseCode());
                auto body = req.String().SubStr(0, 100);
                NotifyWarning("Response body: " + body);
                failCount++;
                if (failCount >= 3) {
                    DownloadProgress::Error("Failed to download " + this.url);
                }
            }
        }
    }

    // for overriding
    void DoneCallback() {
        // trace("Download done (CB): " + this.url);
    }
}

AssetDownload@[] g_ActiveDownloads;
bool g_HasAddedDownloads = false;

void AddArbitraryAssetDownload(const string &in gameDataDir, const string &in fileName, bool force = false) {
    if (!force && GameDataFileExists(gameDataDir + "/" + fileName)) {
        return;
    }
    g_HasAddedDownloads = true;
    g_ActiveDownloads.InsertLast(AssetDownload(SourceBaseUrl + fileName, GetFullGameDataPath(gameDataDir, fileName)));
}

const int MAX_DLS = 30;

void UpdateDownloads() {
    if (g_ActiveDownloads.Length == 0) return;
    AssetDownload@ dl;
    for (int i = Math::Min(MAX_DLS, g_ActiveDownloads.Length) - 1; i >= 0; i--) {
        @dl = g_ActiveDownloads[i];
        if (dl is null || dl.finished) {
            g_ActiveDownloads.RemoveAt(i);
        }
        if (!dl.started) {
            dl.Start();
        }
    }
}







namespace DownloadProgress {
    uint count = 0;
    uint done = 0;
    uint errored = 0;
    string currLabel = "Download";

    bool get_IsNotDone() {
        return count > 0;
    }

    void Add(uint n, const string &in newLabel = "") {
        count += n;
        if (newLabel.Length > 0)
            currLabel = newLabel;
    }
    void Done(uint n = 1) {
        done += n;
        if (done >= count) {
            Reset();
        }
    }
    void Reset() {
        count = 0;
        done = 0;
        errored = 0;
    }
    void SubOne() {
        count -= 1;
    }
    void Error(const string &in msg) {
        errored++;
        done++;
        warn(currLabel + " Error: " + msg);
    }

    void Draw() {
        if (count == 0) return;
        if (count == done) {
            Reset();
            return;
        }

        UI::SetNextWindowPos(Draw::GetWidth() * 9 / 20, Draw::GetHeight() * 4 / 20, UI::Cond::Appearing);
        if (UI::Begin(currLabel + " Progress", UI::WindowFlags::AlwaysAutoResize | UI::WindowFlags::NoCollapse | UI::WindowFlags::NoCollapse)) {
            UI::Text(currLabel + " Progress:          ");
            UI::ProgressBar(float(done) / float(count), vec2(UI::GetContentRegionAvail().x, 40), tostring(done) + " / " + tostring(count) + (errored > 0 ? " / Err: " + errored : ""));
            UI::Separator();
            UI::TextWrapped("\\$aaaIf this appears to hang for a long time, try reloading the plugin under Developer > Reload > Dips++");
        }
        UI::End();
    }
}
