const { app, BrowserWindow, screen } = require('electron')

const createWindow = () => {
  const win = new BrowserWindow({
    frame:false,
    // fullscreen:true,
    webPreferences: {
      hardwareAcceleration: true,
    },
  })
  const mainScreen = screen.getPrimaryDisplay();
  const { width, height } = mainScreen.size;
  win.setSize(width, height);
  win.setPosition(0,0)
  win.setFullScreen(true)
  win.loadURL("http://127.0.0.1:739")

}
app.whenReady().then(() => {
  createWindow()
})