/*
 * WebcamFX (C-style doc, OO implementation)
 * ------------------------------------------------------------
 * PURPOSE
 *   Draw webcam frames into <canvas> elements and apply per-pixel filters.
 *
 * USAGE
 *   A) Zero-JS setup: add <canvas data-webcam-filter="emboss">...</canvas>
 *      Options via data- attributes:
 *        data-webcam-filter="normal|gray|inverse|red|emboss"
 *        data-facing="user|environment"     (default: user)
 *        data-mirror="true|false"           (default: true)
 *
 *   B) Programmatic:
 *      const fx = new WebcamFX.WebcamFilterCanvas(canvas, { filter:"gray" });
 *      await WebcamFX.ensureStream(); // optional—auto-called on first start
 *      fx.start(); fx.setFilter("red"); fx.stop();
 *
 * COMPAT
 *   - Modern Chromium/Firefox/Safari. Requires HTTPS or localhost.
 *   - OffscreenCanvas used when available; falls back automatically.
 */

(function (global){
  "use strict";

  // ---------- Utilities ----------
  const rAF = window.requestAnimationFrame || function (fn){ return setTimeout(fn, 16); };

  // ---------- Filters (C-style pure functions) ----------
  const Filters = {
    normal(w,h, bCtx, gCtx){
      const pixels = bCtx.getImageData(0,0,w,h);
      gCtx.putImageData(pixels, 0, 0);
    },
    gray(w,h, bCtx, gCtx){
      const p = bCtx.getImageData(0,0,w,h);
      const d = p.data;
      for (let i=0; i<d.length; i+=4){
        const avg = ((d[i] + d[i+1] + d[i+2]) / 3) | 0;
        d[i] = d[i+1] = d[i+2] = avg; d[i+3] = 255;
      }
      gCtx.putImageData(p,0,0);
    },
    inverse(w,h, bCtx, gCtx){
      const p = bCtx.getImageData(0,0,w,h);
      const d = p.data;
      for (let i=0; i<d.length; i+=4){
        const avg = ((d[i] + d[i+1] + d[i+2]) / 3) | 0;
        const inv = 255 - avg;
        d[i] = d[i+1] = d[i+2] = inv; d[i+3] = 255;
      }
      gCtx.putImageData(p,0,0);
    },
    red(w,h, bCtx, gCtx){
      const p = bCtx.getImageData(0,0,w,h);
      const d = p.data;
      for (let i=0; i<d.length; i+=4){
        d[i+1] = 0; d[i+2] = 0; d[i+3] = 255; // keep R, zero G/B
      }
      gCtx.putImageData(p,0,0);
    },
    emboss(w,h, bCtx, gCtx){
      // Emboss: write a blended inverted gray into the pixel 2-left (same row)
      const p = bCtx.getImageData(0,0,w,h);
      const d = p.data;
      const stride = w * 4;
      for (let y=0; y<h; y++){
        const row = y * stride;
        for (let x=0; x<w; x++){
          const i = row + x*4;
          const avg = ((d[i] + d[i+1] + d[i+2]) / 3) | 0;
          const inv = 255 - avg;
          if (x >= 2){
            const j = i - 8; // 2 * 4 bytes
            const mOld = ((d[j] + d[j+1] + d[j+2]) / 3) | 0;
            const mNew = ((mOld + inv) / 2) | 0;
            d[j] = d[j+1] = d[j+2] = mNew; d[j+3] = 255;
          }
        }
      }
      gCtx.putImageData(p,0,0);
    }
  };

  // ---------- Stream Manager (singleton) ----------
  const StreamManager = {
    stream: null,
    facingMode: "user",
    video: null,

    async ensureStream(opts={}){
      // If already present, reuse
      if (this.stream && this.video && !this._needsFacingChange(opts.facingMode)) {
        return this.stream;
      }
      // Need (re)start with desired facingMode
      this.facingMode = opts.facingMode || "user";
      if (this.stream){
        this._stopStream();
      }
      const constraints = { video: { facingMode: this.facingMode }, audio:false };
      this.stream = await navigator.mediaDevices.getUserMedia(constraints);

      if (!this.video){
        this.video = document.createElement("video");
        this.video.playsInline = true;
        this.video.muted = true;
        this.video.style.display = "none";
        document.body.appendChild(this.video);
      }
      this.video.srcObject = this.stream;
      await this.video.play();
      return this.stream;
    },

    _needsFacingChange(next){
      return next && next !== this.facingMode;
    },

    _stopStream(){
      try { this.stream.getTracks().forEach(t => t.stop()); } catch(e){}
      this.stream = null;
    },

    getVideo(){
      return this.video;
    },

    getSize(){
      const v = this.video;
      const w = v?.videoWidth  || 640;
      const h = v?.videoHeight || 480;
      return { w, h };
    }
  };

  // ---------- Instance Class ----------
  class WebcamFilterCanvas {
    constructor(canvasEl, options = {}){
      this.canvas = canvasEl;
      this.ctx = canvasEl.getContext("2d", { willReadFrequently: true });
      this.filter = (options.filter || "emboss").toLowerCase();
      this.mirror = (String(options.mirror ?? "true").toLowerCase() === "true");
      this.facingMode = (options.facingMode || "user");
      this.running = false;

      // Backbuffer
      if (typeof OffscreenCanvas !== "undefined"){
        this.back = new OffscreenCanvas(this.canvas.width || 640, this.canvas.height || 480);
      } else {
        this.back = document.createElement("canvas");
        this.back.width = this.canvas.width || 640;
        this.back.height = this.canvas.height || 480;
      }
      this.bCtx = this.back.getContext("2d", { willReadFrequently: true });
    }

    async start(){
      await StreamManager.ensureStream({ facingMode: this.facingMode });
      this._resizeToVideo();
      this.running = true;
      Loop.add(this);
    }

    stop(){
      this.running = false;
      Loop.remove(this);
      // Note: stream is shared; we do not stop it here.
    }

    setFilter(name){
      this.filter = (name || "normal").toLowerCase();
    }

    setMirror(on){
      this.mirror = !!on;
    }

    setFacingMode(mode){
      this.facingMode = mode === "environment" ? "environment" : "user";
    }

    _resizeToVideo(){
      const { w, h } = StreamManager.getSize();
      // Keep canvas's width/height attrs aligned with video aspect
      if (!this.canvas.width || !this.canvas.height){
        // If author defined only CSS size, we adopt the video size
        this.canvas.width = w;
        this.canvas.height = h;
      }
      this.back.width = this.canvas.width;
      this.back.height = this.canvas.height;
    }

    // Called each frame by the Loop
    draw(){
      if (!this.running) return;

      const video = StreamManager.getVideo();
      if (!video || !video.videoWidth) return;

      const w = this.canvas.width;
      const h = this.canvas.height;

      // Draw into backbuffer (optionally mirrored)
      this.bCtx.save();
      if (this.mirror){
        this.bCtx.translate(w, 0);
        this.bCtx.scale(-1, 1);
      }
      this.bCtx.drawImage(video, 0, 0, w, h);
      this.bCtx.restore();

      // Apply filter
      const fn = Filters[this.filter] || Filters.normal;
      fn(w, h, this.bCtx, this.ctx);
    }
  }

  // ---------- Global Draw Loop ----------
  const Loop = {
    list: new Set(),
    ticking: false,

    add(instance){
      this.list.add(instance);
      if (!this.ticking){
        this.ticking = true;
        this.tick();
      }
    },
    remove(instance){
      this.list.delete(instance);
      if (this.list.size === 0){
        this.ticking = false;
      }
    },
    tick(){
      if (!this.ticking) return;
      this.list.forEach(inst => inst.draw());
      rAF(()=> this.tick());
    }
  };

  // ---------- Auto-init on canvases with data attributes ----------
  async function autoInit(){
    const nodes = document.querySelectorAll('canvas[data-webcam-filter]');
    if (!nodes.length) return;

    // Ensure stream once with best facingMode among nodes (prefer "user" default)
    const firstFacing = [...nodes].map(n => (n.getAttribute('data-facing') || 'user')).find(Boolean) || 'user';
    await StreamManager.ensureStream({ facingMode: firstFacing });

    nodes.forEach(node => {
      const opts = {
        filter: node.getAttribute('data-webcam-filter') || 'emboss',
        facingMode: node.getAttribute('data-facing') || 'user',
        mirror: node.getAttribute('data-mirror') ?? 'true',
      };
      const inst = new WebcamFilterCanvas(node, opts);
      inst.start();
      // Store handle if needed later
      node._webcamFX = inst;
    });
  }

  // Expose API
  const WebcamFX = {
    WebcamFilterCanvas,
    Filters,
    ensureStream: (opts)=> StreamManager.ensureStream(opts),
    stopSharedStream: ()=> StreamManager._stopStream(),
    _streamManager: StreamManager, // for advanced users
  };

  global.WebcamFX = WebcamFX;

  // Auto-run when DOM is ready
  if (document.readyState === "loading"){
    document.addEventListener("DOMContentLoaded", autoInit, { once:true });
  } else {
    autoInit();
  }

})(window);
