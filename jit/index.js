(async function() {
  if (false) {
    let scope = new URL("./", location.href).toString();
    let registrations = await navigator.serviceWorker.getRegistrations();
    registrations.find((registration) => {
      return registration && registration.active && registration.active.scriptURL == `${scope}service-worker.js`;
    })?.unregister();
    return;
  }
  if (typeof window.require == "function" && typeof window.process == "object" && typeof window.__dirname == "string") {
    if (window.__dirname.endsWith("electron.asar\\renderer") || window.__dirname.endsWith("electron.asar/renderer")) {
      const path = require("path");
      if (window.process.platform === "darwin") {
        window.__dirname = path.join(window.process.resourcesPath, "app");
      } else {
        window.__dirname = path.join(path.resolve(), "resources/app");
      }
      const oldRequire = window.require;
      window.require = function(moduleId) {
        try {
          return oldRequire(moduleId);
        } catch {
          return oldRequire(path.join(window.__dirname, moduleId));
        }
      };
      Object.entries(oldRequire).forEach(([key, value]) => {
        window.require[key] = value;
      });
    }
  }
  const globalText = {
    SERVICE_WORKER_NOT_SUPPORT: ["无法启用即时编译功能", "您使用的客户端或浏览器不支持启用serviceWorker", "请确保您的客户端或浏览器使用http://localhost或https协议打开《无名杀》并且启用serviceWorker"].join("\n"),
    SERVICE_WORKER_LOAD_FAILED: ["无法启用即时编译功能", "serviceWorker加载失败", "可能会导致部分扩展加载失败"].join("\n")
  };
  if (!("serviceWorker" in navigator)) {
    alert(globalText.SERVICE_WORKER_NOT_SUPPORT);
  } else {
    let scope = new URL("./", location.href).toString();
    let registrations = await navigator.serviceWorker.getRegistrations();
    let findServiceWorker = registrations.find((registration) => {
      return registration && registration.active && registration.active.scriptURL == `${scope}service-worker.js`;
    });
    try {
      const registration = await navigator.serviceWorker.register(`${scope}service-worker.js`, {
        type: "module",
        updateViaCache: "all",
        scope
      });
      if (!findServiceWorker) {
        window.location.reload();
      }
      navigator.serviceWorker.addEventListener("message", (e) => {
        if (e.data?.type === "reload") {
          window.location.reload();
        }
      });
      registration.update().catch((e) => console.error("worker update失败", e));
      if (sessionStorage.getItem("canUseTs") !== "true") {
        const path = "./test/canUse.ts";
        await import(
          /* @vite-ignore */
          path
        ).then(() => sessionStorage.setItem("canUseTs", "true")).catch((e) => {
          if (sessionStorage.getItem("canUseTs") === "false") throw e;
          sessionStorage.setItem("canUseTs", "false");
          window.location.reload();
        });
      }
    } catch (e) {
      console.log("serviceWorker加载失败: ", e);
      alert(globalText.SERVICE_WORKER_LOAD_FAILED);
    }
  }
})();
