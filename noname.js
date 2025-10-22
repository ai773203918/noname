import { GNC, gnc, setGNC } from "./noname/gnc/index.js";
import { AI, ai, setAI } from "./noname/ai/index.js";
import { Game, game, setGame } from "./noname/game/index.js";
import { Get, get, setGet } from "./noname/get/index.js";
import { Library, lib, setLibrary } from "./noname/library/index.js";
import { _status, setStatus, status } from "./noname/status/index.js";
import { UI, setUI, ui } from "./noname/ui/index.js";
import { boot } from "./noname/init/index.js";
let url = new URL("./", import.meta.url);
if (!url.href.endsWith("/")) {
  url = new URL(url.href + "/");
}
const rootURL = url;
export {
  AI,
  GNC,
  Game,
  Get,
  Library,
  UI,
  _status,
  ai,
  boot,
  game,
  get,
  gnc,
  lib,
  rootURL,
  setAI,
  setGNC,
  setGame,
  setGet,
  setLibrary,
  setStatus,
  setUI,
  status,
  ui
};
