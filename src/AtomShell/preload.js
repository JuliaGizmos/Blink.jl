const { contextBridge, ipcRenderer } = require('electron');

/* This will execute require on the scripts given as arguments and ignore other args because the regex turns them empty (false)  */
process.argv.map(str => str.replace(/((?:^--blink-preloadjs=)|(?:^.*$))/, '')).filter(Boolean).forEach(function (filepath) {
    try {
        require(filepath);
    } catch (err) {
        console.log(err);
    }
});

const dialogHandlers = {
    showOpenDialog: (opts, cb) => ipcRenderer.invoke("dialog:openFile", opts).then(res => cb(res.filePaths)),
    showSaveDialog: (opts, cb) => ipcRenderer.invoke("dialog:saveFile", opts).then(res => cb(res.filePath)),
};

/* If a user disables contextIsolation we'll need to handle that. */
if (process.contextIsolated) {
    contextBridge.exposeInMainWorld('dialog', dialogHandlers);
} else {
    window.dialog = dialogHandlers;
}
