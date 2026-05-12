"use client";
/**
 * Immersive voice page — Siri / ChatGPT Voice style.
 *
 * Connects to ws://<host>/api/v1/voice/stream and streams:
 *   - mic audio (WebM/Opus from MediaRecorder)  → server
 *   - JSON control messages                      → server
 *   - JSON state events + binary WAV chunks      ← server
 *
 * UI states:
 *   idle       — orb is calm, prompt to start
 *   listening  — orb pulses with mic input, transcript live
 *   thinking   — orb spins, "thinking…"
 *   speaking   — orb breathes to TTS audio, plays response
 *
 * Push-to-talk (default): hold the button, release to send.
 * Auto mode: VAD (energy threshold) detects end-of-speech.
 */
import { useCallback, useEffect, useRef, useState } from "react";

type State = "idle" | "listening" | "thinking" | "speaking" | "disconnected";
type Mode = "push" | "auto";

interface TurnEntry {
  role: "user" | "assistant";
  text: string;
  tool?: string | null;
  source?: string;
  latency_ms?: number;
}

const SILENCE_RMS = 0.012;          // below this is silence
const SILENCE_MS = 800;             // hold silence this long to end turn (auto mode)
const RMS_SMOOTHING = 0.6;          // EWMA for the orb pulse

export default function VoicePage() {
  // ── connection / state ───────────────────────────────────────────────────
  const [connected, setConnected] = useState(false);
  const [state, setState] = useState<State>("idle");
  const [mode, setMode] = useState<Mode>("push");
  const [sttAvailable, setSttAvailable] = useState(true);
  const [ttsAvailable, setTtsAvailable] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // ── conversation ─────────────────────────────────────────────────────────
  const [history, setHistory] = useState<TurnEntry[]>([]);
  const [liveTranscript, setLiveTranscript] = useState("");

  // ── audio + UI refs ──────────────────────────────────────────────────────
  const wsRef = useRef<WebSocket | null>(null);
  const recorderRef = useRef<MediaRecorder | null>(null);
  const audioCtxRef = useRef<AudioContext | null>(null);
  const analyserRef = useRef<AnalyserNode | null>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const rmsRef = useRef(0);
  const silenceStartRef = useRef<number | null>(null);
  const recordingRef = useRef(false);
  const animRef = useRef<number | null>(null);
  const ttsQueueRef = useRef<HTMLAudioElement[]>([]);
  const ttsPlayingRef = useRef(false);

  // ── connect on mount ─────────────────────────────────────────────────────
  useEffect(() => {
    connect();
    return () => {
      cleanup();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function connect() {
    const proto = window.location.protocol === "https:" ? "wss:" : "ws:";
    const url = `${proto}//${window.location.host}/api/v1/voice/stream`;
    const ws = new WebSocket(url);
    ws.binaryType = "arraybuffer";

    ws.onopen = () => {
      setConnected(true);
      setError(null);
    };

    ws.onmessage = (e) => handleServerMessage(e.data);

    ws.onclose = () => {
      setConnected(false);
      setState("disconnected");
    };
    ws.onerror = () => setError("WebSocket error");

    wsRef.current = ws;
  }

  function handleServerMessage(data: string | ArrayBuffer) {
    if (typeof data === "string") {
      try {
        const msg = JSON.parse(data);
        switch (msg.type) {
          case "ready":
            setSttAvailable(!!msg.stt_available);
            setTtsAvailable(!!msg.tts_available);
            break;
          case "state":
            setState(msg.state as State);
            break;
          case "transcript":
            setLiveTranscript(msg.text);
            if (msg.is_final) {
              setHistory((h) => [...h, { role: "user", text: msg.text }]);
              setLiveTranscript("");
            }
            break;
          case "response":
            setHistory((h) => [...h, {
              role: "assistant",
              text: msg.text,
              tool: msg.tool_used,
              source: msg.answer_source,
              latency_ms: msg.latency_ms,
            }]);
            break;
          case "tts_start":
            ttsQueueRef.current = [];
            ttsPlayingRef.current = true;
            break;
          case "tts_end":
            ttsPlayingRef.current = false;
            break;
          case "tts_interrupted":
            ttsQueueRef.current.forEach((a) => { try { a.pause(); } catch {} });
            ttsQueueRef.current = [];
            ttsPlayingRef.current = false;
            break;
          case "tts_skip":
            ttsPlayingRef.current = false;
            break;
          case "error":
            setError(msg.message);
            break;
        }
      } catch {
        // ignore non-JSON text frames
      }
    } else {
      // Binary frame = WAV chunk
      playWavChunk(data);
    }
  }

  function playWavChunk(buf: ArrayBuffer) {
    const blob = new Blob([buf], { type: "audio/wav" });
    const url = URL.createObjectURL(blob);
    const audio = new Audio(url);
    audio.onended = () => URL.revokeObjectURL(url);
    ttsQueueRef.current.push(audio);
    audio.play().catch(() => {/* autoplay block — fine */});
  }

  // ── mic capture ──────────────────────────────────────────────────────────
  async function startRecording() {
    if (recordingRef.current) return;
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      streamRef.current = stream;

      // VAD: analyser node for RMS-based silence detection + orb pulse
      const ctx = new AudioContext();
      audioCtxRef.current = ctx;
      const src = ctx.createMediaStreamSource(stream);
      const analyser = ctx.createAnalyser();
      analyser.fftSize = 1024;
      src.connect(analyser);
      analyserRef.current = analyser;

      // MediaRecorder for actual audio bytes
      const rec = new MediaRecorder(stream, { mimeType: "audio/webm;codecs=opus" });
      rec.ondataavailable = (e) => {
        if (e.data.size > 0 && wsRef.current?.readyState === WebSocket.OPEN) {
          e.data.arrayBuffer().then((buf) => wsRef.current?.send(buf));
        }
      };
      rec.start(250); // emit chunks every 250 ms
      recorderRef.current = rec;
      recordingRef.current = true;
      silenceStartRef.current = null;

      // Start RMS animation loop (drives orb + auto VAD)
      tickVAD();
    } catch (e) {
      setError(`Microphone error: ${String(e)}`);
    }
  }

  function tickVAD() {
    if (!recordingRef.current || !analyserRef.current) {
      animRef.current = null;
      return;
    }
    const arr = new Float32Array(analyserRef.current.fftSize);
    analyserRef.current.getFloatTimeDomainData(arr);
    let sum = 0;
    for (let i = 0; i < arr.length; i++) sum += arr[i] * arr[i];
    const rms = Math.sqrt(sum / arr.length);
    rmsRef.current = rmsRef.current * RMS_SMOOTHING + rms * (1 - RMS_SMOOTHING);

    // Auto-stop on silence
    if (mode === "auto") {
      const now = performance.now();
      if (rms < SILENCE_RMS) {
        if (silenceStartRef.current == null) silenceStartRef.current = now;
        else if (now - silenceStartRef.current > SILENCE_MS) {
          stopRecording();
          return;
        }
      } else {
        silenceStartRef.current = null;
      }
    }

    animRef.current = requestAnimationFrame(tickVAD);
  }

  function stopRecording() {
    if (!recordingRef.current) return;
    recordingRef.current = false;
    recorderRef.current?.stop();
    recorderRef.current = null;
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;
    if (animRef.current) cancelAnimationFrame(animRef.current);
    animRef.current = null;
    audioCtxRef.current?.close();
    audioCtxRef.current = null;
    analyserRef.current = null;

    // Finalize on server
    wsRef.current?.send(JSON.stringify({ type: "end" }));
  }

  function sendInterrupt() {
    wsRef.current?.send(JSON.stringify({ type: "interrupt" }));
    ttsQueueRef.current.forEach((a) => { try { a.pause(); } catch {} });
    ttsQueueRef.current = [];
    ttsPlayingRef.current = false;
  }

  function cleanup() {
    stopRecording();
    wsRef.current?.close();
    wsRef.current = null;
  }

  // ── orb pulse animation ──────────────────────────────────────────────────
  const orbScale = (() => {
    if (state === "listening") return 1 + Math.min(rmsRef.current * 12, 0.5);
    if (state === "thinking") return 1;
    if (state === "speaking") return 1.05 + Math.sin(Date.now() / 200) * 0.05;
    return 1;
  })();

  // Force re-render at 30fps while in active states (cheap — just a counter)
  const [, force] = useState(0);
  useEffect(() => {
    if (state === "idle" || state === "disconnected") return;
    const t = setInterval(() => force((x) => x + 1), 33);
    return () => clearInterval(t);
  }, [state]);

  // ── push-to-talk handlers ────────────────────────────────────────────────
  const onPressStart = useCallback(() => {
    if (state === "speaking") sendInterrupt();
    if (mode === "push") startRecording();
  }, [mode, state]);

  const onPressEnd = useCallback(() => {
    if (mode === "push") stopRecording();
  }, [mode]);

  const onToggleAuto = useCallback(() => {
    if (state === "listening") stopRecording();
    setMode((m) => (m === "push" ? "auto" : "push"));
  }, [state]);

  const onAutoToggleMic = useCallback(() => {
    if (recordingRef.current) stopRecording();
    else startRecording();
  }, []);

  // ── render ──────────────────────────────────────────────────────────────
  const statusLabel = (
    !connected      ? "Connecting…" :
    state === "idle"      ? (mode === "push" ? "Hold to talk" : "Tap to start") :
    state === "listening" ? "Listening…" :
    state === "thinking"  ? "Thinking…" :
    state === "speaking"  ? "Speaking…" :
    state === "disconnected" ? "Disconnected" : ""
  );

  return (
    <div className="voice-page">
      <style>{VOICE_CSS}</style>

      {/* Conversation history — top half, scrollable */}
      <div className="voice-history">
        {history.length === 0 && !liveTranscript && (
          <div className="voice-history-empty">
            Talk to your second brain. Ask anything.
          </div>
        )}
        {history.map((t, i) => (
          <div key={i} className={`voice-turn voice-turn-${t.role}`}>
            <div className="voice-turn-bubble">{t.text}</div>
            {t.role === "assistant" && (t.tool || t.source) && (
              <div className="voice-turn-meta">
                {t.tool && <span className="voice-chip voice-chip-green">{t.tool}</span>}
                {t.source && <span className="voice-chip">{t.source}</span>}
                {t.latency_ms != null && <span className="voice-chip">{t.latency_ms}ms</span>}
              </div>
            )}
          </div>
        ))}
        {liveTranscript && (
          <div className="voice-turn voice-turn-user voice-turn-live">
            <div className="voice-turn-bubble">{liveTranscript}</div>
          </div>
        )}
      </div>

      {/* Center orb */}
      <div className="voice-orb-wrap">
        <div className={`voice-orb voice-orb-${state}`} style={{ transform: `scale(${orbScale})` }} />
        <div className={`voice-orb-ring voice-orb-ring-${state}`} />
        <div className="voice-status">{statusLabel}</div>
      </div>

      {/* Bottom controls */}
      <div className="voice-controls">
        {error && <div className="voice-error">{error}</div>}

        {!sttAvailable && (
          <div className="voice-warn">
            STT unavailable — install <code>faster-whisper</code> on the server for real transcription.
          </div>
        )}
        {!ttsAvailable && (
          <div className="voice-warn">
            TTS unavailable — install <code>piper-tts</code> + download a voice for spoken responses.
          </div>
        )}

        <div className="voice-buttons">
          {mode === "push" ? (
            <button
              className={`voice-mic voice-mic-${state}`}
              onMouseDown={onPressStart}
              onMouseUp={onPressEnd}
              onMouseLeave={onPressEnd}
              onTouchStart={(e) => { e.preventDefault(); onPressStart(); }}
              onTouchEnd={(e) => { e.preventDefault(); onPressEnd(); }}
              disabled={!connected || state === "thinking"}
            >
              {state === "listening" ? "● Release" : "Hold to talk"}
            </button>
          ) : (
            <button
              className={`voice-mic voice-mic-${state}`}
              onClick={onAutoToggleMic}
              disabled={!connected || state === "thinking"}
            >
              {recordingRef.current ? "■ Stop" : "● Start"}
            </button>
          )}

          <button className="voice-secondary" onClick={onToggleAuto}>
            {mode === "push" ? "Switch to auto" : "Switch to push-to-talk"}
          </button>

          {state === "speaking" && (
            <button className="voice-secondary voice-interrupt" onClick={sendInterrupt}>
              ✕ Interrupt
            </button>
          )}
        </div>

        <div className="voice-conn-row">
          <span className={`voice-dot ${connected ? "voice-dot-on" : "voice-dot-off"}`} />
          <span className="voice-conn-label">
            {connected ? `connected · session active` : "disconnected"}
          </span>
        </div>
      </div>
    </div>
  );
}

// ── styles ──────────────────────────────────────────────────────────────────
const VOICE_CSS = `
.voice-page {
  position: fixed;
  inset: 0;
  margin-left: var(--sidebar-w);
  display: flex;
  flex-direction: column;
  background: radial-gradient(ellipse at center, #14142a 0%, #08080f 70%);
  color: var(--text);
  overflow: hidden;
}

/* ── conversation history ─────────────────────────────────────────────── */
.voice-history {
  flex: 1;
  overflow-y: auto;
  padding: 32px 24px 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  max-width: 720px;
  width: 100%;
  margin: 0 auto;
}
.voice-history-empty {
  margin: auto;
  text-align: center;
  color: var(--dim);
  font-size: 13px;
}
.voice-turn { display: flex; flex-direction: column; max-width: 100%; }
.voice-turn-user { align-items: flex-end; }
.voice-turn-assistant { align-items: flex-start; }
.voice-turn-bubble {
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.06);
  border-radius: 16px;
  padding: 10px 16px;
  font-size: 14.5px;
  line-height: 1.55;
  max-width: 560px;
  white-space: pre-wrap;
  word-break: break-word;
  backdrop-filter: blur(6px);
}
.voice-turn-user .voice-turn-bubble {
  background: linear-gradient(135deg, rgba(123,151,255,0.20), rgba(167,139,250,0.18));
  border-color: rgba(123,151,255,0.30);
}
.voice-turn-live .voice-turn-bubble {
  opacity: 0.65;
  font-style: italic;
}
.voice-turn-meta {
  display: flex; gap: 6px; margin-top: 4px; padding: 0 6px;
  flex-wrap: wrap;
}
.voice-chip {
  font-size: 10px; padding: 2px 8px; border-radius: 999px;
  background: rgba(255,255,255,0.04);
  border: 1px solid rgba(255,255,255,0.06);
  color: var(--text2);
}
.voice-chip-green { color: var(--green); border-color: rgba(110,231,183,0.25); }

/* ── orb ──────────────────────────────────────────────────────────────── */
.voice-orb-wrap {
  position: relative;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  padding: 16px 0 8px;
}
.voice-orb {
  width: 168px; height: 168px; border-radius: 50%;
  background: radial-gradient(circle at 30% 30%, #a78bfa 0%, #7b97ff 50%, #4f5bd5 100%);
  box-shadow:
    0 0 80px rgba(123,151,255,0.45),
    0 0 160px rgba(167,139,250,0.25),
    inset 0 0 40px rgba(255,255,255,0.15);
  transition: transform 0.08s ease-out;
  will-change: transform;
}
.voice-orb-thinking {
  background: conic-gradient(from 0deg, #7b97ff, #a78bfa, #7b97ff);
  animation: voice-spin 2.4s linear infinite;
}
.voice-orb-speaking {
  background: radial-gradient(circle at 30% 30%, #6ee7b7 0%, #4ade80 60%, #16a34a 100%);
  box-shadow:
    0 0 100px rgba(110,231,183,0.55),
    inset 0 0 60px rgba(255,255,255,0.18);
}
.voice-orb-disconnected {
  background: radial-gradient(circle, #555 0%, #333 100%);
  opacity: 0.55;
  box-shadow: none;
}
@keyframes voice-spin { to { transform: rotate(360deg); } }

.voice-orb-ring {
  position: absolute; top: 50%; left: 50%;
  width: 200px; height: 200px; margin: -100px 0 0 -100px;
  border-radius: 50%; pointer-events: none;
  border: 2px solid rgba(123,151,255,0.0);
  transition: border-color 0.4s;
}
.voice-orb-ring-listening { animation: voice-ring-pulse 1.2s ease-out infinite; }
@keyframes voice-ring-pulse {
  0%   { border-color: rgba(123,151,255,0.55); transform: scale(0.95); }
  100% { border-color: rgba(123,151,255,0);    transform: scale(1.35); }
}

.voice-status {
  margin-top: 16px;
  font-size: 13px;
  letter-spacing: 0.04em;
  text-transform: uppercase;
  color: var(--text2);
}

/* ── bottom controls ──────────────────────────────────────────────────── */
.voice-controls {
  padding: 16px 24px 28px;
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 8px;
}
.voice-error {
  background: rgba(248,113,113,0.08);
  border: 1px solid rgba(248,113,113,0.25);
  color: var(--red);
  font-size: 12px;
  padding: 6px 12px;
  border-radius: 6px;
}
.voice-warn {
  font-size: 11px; color: var(--yellow);
  background: rgba(251,191,36,0.06);
  border: 1px solid rgba(251,191,36,0.20);
  padding: 5px 10px; border-radius: 6px;
}
.voice-buttons {
  display: flex; gap: 10px; align-items: center; flex-wrap: wrap;
  justify-content: center; margin-top: 4px;
}
.voice-mic {
  background: var(--accent);
  color: #0b0b10;
  border: none;
  border-radius: 999px;
  padding: 14px 32px;
  font-size: 14px;
  font-weight: 600;
  cursor: pointer;
  user-select: none;
  transition: transform 0.1s, background 0.15s;
  box-shadow: 0 6px 20px rgba(123,151,255,0.35);
}
.voice-mic:hover:not(:disabled)  { background: #8fa8ff; }
.voice-mic:active                { transform: scale(0.97); }
.voice-mic:disabled              { opacity: 0.4; cursor: not-allowed; box-shadow: none; }
.voice-mic-listening             { background: var(--red); box-shadow: 0 6px 20px rgba(248,113,113,0.45); }
.voice-mic-listening:hover:not(:disabled) { background: #fb8e8e; }

.voice-secondary {
  background: transparent;
  color: var(--text2);
  border: 1px solid var(--border);
  border-radius: 999px;
  padding: 10px 18px;
  font-size: 12px;
  cursor: pointer;
}
.voice-secondary:hover { color: var(--text); border-color: var(--border2); }
.voice-interrupt { border-color: var(--red); color: var(--red); }

.voice-conn-row {
  display: flex; align-items: center; gap: 6px;
  margin-top: 6px;
  font-size: 11px;
  color: var(--dim);
}
.voice-dot {
  width: 6px; height: 6px; border-radius: 50%;
}
.voice-dot-on  { background: var(--green); box-shadow: 0 0 6px var(--green); }
.voice-dot-off { background: var(--dim); }
.voice-conn-label { font-family: var(--mono); }

/* ── mobile ───────────────────────────────────────────────────────────── */
@media (max-width: 720px) {
  .voice-page { margin-left: 0; }
  .voice-history { padding: 20px 14px 8px; }
  .voice-orb { width: 132px; height: 132px; }
  .voice-orb-ring { width: 160px; height: 160px; margin: -80px 0 0 -80px; }
}
`;
