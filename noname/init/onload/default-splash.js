import "../../../noname.js";
import "../../../node_modules/.pnpm/vue@3.5.21_typescript@5.9.2/node_modules/vue/dist/vue.runtime.esm-bundler.js";
import "./OnloadSplash.vue.js";
import { lib } from "../../library/index.js";
import { createApp } from "../../../node_modules/.pnpm/@vue_runtime-dom@3.5.21/node_modules/@vue/runtime-dom/dist/runtime-dom.esm-bundler.js";
import _sfc_main from "./OnloadSplash.vue2.js";
import { ui } from "../../ui/index.js";
import { game } from "../../game/index.js";
class DefaultSplash {
  id = "style1";
  name = "样式一";
  path = "image/splash/style1/";
  resolve;
  app;
  clicked;
  async init(node, resolve) {
    this.resolve = resolve;
    if (lib.config.touchscreen) {
      node.classList.add("touch");
      lib.setScroll(node);
    }
    if (lib.config.player_border !== "wide") {
      node.classList.add("slim");
    }
    node.dataset.radius_size = lib.config.radius_size;
    node.dataset.splash_style = lib.config.splash_style;
    this.app = createApp(_sfc_main, {
      handle: this.handle.bind(this),
      click: this.click.bind(this)
    });
    this.app.mount(node);
    if (lib.config.mousewheel) {
      node.addEventListener("wheel", ui.click.mousewheel);
    }
  }
  async dispose(node) {
    node.delete(1e3);
    await new Promise((resolve) => this.clicked.listenTransition(resolve, 500));
    return true;
  }
  preview(node) {
    node.className = "button character";
    node.style.width = "200px";
    node.style.height = `${node.offsetWidth * 1080 / 2400}px`;
    node.style.display = "flex";
    node.style.flexDirection = "column";
    node.style.alignItems = "center";
    node.style.backgroundSize = "100% 100%";
    node.setBackgroundImage(`image/splash/${this.id}.jpg`);
  }
  handle(mode) {
    return lib.path.join(this.path, `${mode}.jpg`);
  }
  click(mode, node) {
    node.classList.add("clicked");
    if (game.layout !== "mobile" && lib.layoutfixed.indexOf(mode) !== -1) {
      game.layout = "mobile";
      ui.css.layout.href = `${lib.assetURL}layout/${game.layout}/layout.css`;
    } else if (game.layout === "mobile" && lib.config.layout !== "mobile" && lib.layoutfixed.indexOf(mode) === -1) {
      game.layout = lib.config.layout;
      if (game.layout === "default") {
        ui.css.layout.href = "";
      } else {
        ui.css.layout.href = `${lib.assetURL}layout/${game.layout}/layout.css`;
      }
    }
    this.clicked = node;
    this.resolve(mode);
  }
}
export {
  DefaultSplash
};
