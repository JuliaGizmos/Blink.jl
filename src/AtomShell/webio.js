// IIFE to avoid polluting namespace
(function() {
  // window._webIOBundlePath should be set before this script is included.
  if (typeof window._webIOBundlePath === undefined) {
    throw new Error("window._webIOBundlePath is undefined!");
  }
  const WebIOLib = require(window._webIOBundlePath);

  // The WebIO class is exported as default from the module.
  const WebIO = window.WebIO = new WebIOLib.default();
  WebIO.setSendCallback((message) => {
    Blink.msg("webio", message);
  });
  Blink.handlers.webio = (message) => {
    WebIO.dispatch(message.data);
  };
})();
