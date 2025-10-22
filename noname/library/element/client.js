import "../../../noname.js";
import exports from "../../util/security.js";
import { get } from "../../get/index.js";
import { lib } from "../index.js";
import { ui } from "../../ui/index.js";
import { _status } from "../../status/index.js";
import { game } from "../../game/index.js";
class Client {
  /**
   * @param {import('../index.js').NodeWS | InstanceType<typeof import('ws').WebSocket> | Client} ws
   * @param {boolean} temp
   */
  constructor(ws, temp = false) {
    if (ws instanceof Client) {
      throw new Error("Client cannot copy.");
    }
    this.ws = ws;
    this.id = ws.wsid || get.id();
    this.closed = false;
    if (!temp) {
      this.sandbox = exports.createSandbox(this.id);
      if (this.sandbox) {
        Reflect.defineProperty(this, "sandbox", {
          value: this.sandbox,
          writable: false,
          configurable: false
        });
        Reflect.defineProperty(this.sandbox, "client", {
          value: this,
          writable: false,
          configurable: false
        });
      }
    }
  }
  send() {
    if (this.closed) {
      return this;
    }
    var args = Array.from(arguments);
    if (typeof args[0] == "function") {
      args.unshift("exec");
    }
    for (var i = 1; i < args.length; i++) {
      args[i] = get.stringifiedResult(args[i]);
    }
    try {
      this.ws.send(JSON.stringify(args));
    } catch (e) {
      this.ws.close();
    }
    return this;
  }
  close() {
    lib.node.clients.remove(this);
    lib.node.observing.remove(this);
    if (ui.removeObserve && !lib.node.observing.length) {
      ui.removeObserve.remove();
      delete ui.removeObserve;
    }
    this.closed = true;
    if (_status.waitingForPlayer) {
      for (var i = 0; i < game.connectPlayers.length; i++) {
        if (game.connectPlayers[i].playerid == this.id) {
          game.connectPlayers[i].uninitOL();
          delete game.connectPlayers[i].playerid;
        }
      }
      if (game.onlinezhu == this.id) {
        game.onlinezhu = null;
      }
      game.updateWaiting();
    } else if (lib.playerOL[this.id]) {
      var player = lib.playerOL[this.id];
      player.setNickname(player.nickname + " - 离线");
      game.broadcast(function(player2) {
        player2.setNickname(player2.nickname + " - 离线");
      }, player);
      player.unwait("ai");
    }
    if (window.isNonameServer) {
      document.querySelector("#server_count").innerHTML = lib.node.clients.length;
    }
    return this;
  }
}
export {
  Client
};
