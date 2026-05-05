"use client";
import { useRef, useState } from "react";

interface VoiceResult {
  transcript: string;
  source: string;
  query_result?: {
    query: string;
    chunks: { id: string; content: string; source: string; score: number }[];
    answer?: string;
  };
}

type RecordState = "idle" | "recording" | "processing";

export default function VoicePage() {
  const [recState, setRecState] = useState<RecordState>("idle");
  const [transcript, setTranscript] = useState<string | null>(null);
  const [result, setResult] = useState<VoiceResult | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [audioUrl, setAudioUrl] = useState<string | null>(null);

  const mediaRecorder = useRef<MediaRecorder | null>(null);
  const chunks = useRef<Blob[]>([]);
  const fileInputRef = useRef<HTMLInputElement>(null);

  async function startRecording() {
    setError(null);
    setTranscript(null);
    setResult(null);
    setAudioUrl(null);
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true });
      const mr = new MediaRecorder(stream);
      chunks.current = [];
      mr.ondataavailable = (e) => { if (e.data.size) chunks.current.push(e.data); };
      mr.onstop = async () => {
        const blob = new Blob(chunks.current, { type: "audio/webm" });
        setAudioUrl(URL.createObjectURL(blob));
        stream.getTracks().forEach((t) => t.stop());
        await upload(blob, "recording.webm");
      };
      mr.start();
      mediaRecorder.current = mr;
      setRecState("recording");
    } catch (err) {
      setError(`Microphone error: ${String(err)}`);
    }
  }

  function stopRecording() {
    mediaRecorder.current?.stop();
    mediaRecorder.current = null;
    setRecState("processing");
  }

  async function upload(blob: Blob, filename: string) {
    setRecState("processing");
    setError(null);
    try {
      const form = new FormData();
      form.append("file", blob, filename);
      const res = await fetch("/api/v1/voice/input", { method: "POST", body: form });
      if (!res.ok) {
        const body = await res.json().catch(() => ({}));
        throw new Error(body.detail ?? `HTTP ${res.status}`);
      }
      const data: VoiceResult = await res.json();
      setTranscript(data.transcript);
      setResult(data);
    } catch (err) {
      setError(String(err));
    } finally {
      setRecState("idle");
    }
  }

  async function onFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    e.target.value = "";
    setTranscript(null);
    setResult(null);
    setError(null);
    setAudioUrl(URL.createObjectURL(file));
    await upload(file, file.name);
  }

  const busy = recState === "processing";

  return (
    <div className="page">
      <div className="page-header">
        <div className="page-title">Voice Input</div>
        <div className="page-sub">Record or upload audio — transcribed and queried against your vault</div>
      </div>

      {error && <div className="alert alert-error"><span>⚠</span> {error}</div>}

      <div className="card mb-16">
        <div className="card-title">Record</div>
        <div className="row" style={{ gap: 12 }}>
          {recState === "idle" && (
            <button className="btn-primary" onClick={startRecording}>
              ● Start Recording
            </button>
          )}
          {recState === "recording" && (
            <>
              <span className="badge badge-red" style={{ animation: "pulse 1s infinite" }}>● Recording</span>
              <button className="btn-danger" onClick={stopRecording}>■ Stop</button>
            </>
          )}
          {busy && (
            <span className="dim row" style={{ gap: 8 }}>
              <span className="spinner" /> Processing…
            </span>
          )}
        </div>

        {audioUrl && (
          <audio controls src={audioUrl} style={{ marginTop: 16, width: "100%" }} />
        )}
      </div>

      <div className="card mb-16">
        <div className="card-title">Upload File</div>
        <div className="row" style={{ gap: 12 }}>
          <button onClick={() => fileInputRef.current?.click()} disabled={busy || recState === "recording"}>
            ↑ Choose Audio File
          </button>
          <span className="dim" style={{ fontSize: 12 }}>mp3, wav, webm, ogg · max 25 MB</span>
        </div>
        <input
          ref={fileInputRef}
          type="file"
          accept="audio/*"
          style={{ display: "none" }}
          onChange={onFileChange}
        />
      </div>

      {transcript && (
        <div className="card mb-16">
          <div className="card-title">Transcript</div>
          <p style={{ lineHeight: 1.7, whiteSpace: "pre-wrap" }}>{transcript}</p>
          {result?.source && (
            <div className="mt-8">
              <span className="badge badge-default">{result.source}</span>
            </div>
          )}
        </div>
      )}

      {result?.query_result && (
        <div className="card">
          <div className="card-title">Answer</div>
          {result.query_result.answer && (
            <p style={{ lineHeight: 1.7, marginBottom: 16, whiteSpace: "pre-wrap" }}>
              {result.query_result.answer}
            </p>
          )}
          {result.query_result.chunks.length > 0 && (
            <>
              <div className="card-title" style={{ marginTop: 4 }}>
                Sources ({result.query_result.chunks.length})
              </div>
              {result.query_result.chunks.map((c) => (
                <div key={c.id} style={{ marginBottom: 8, background: "var(--surface2)", borderRadius: "var(--radius-sm)", padding: "10px 12px", border: "1px solid var(--border)" }}>
                  <div className="row mb-4">
                    <span className="mono dim" style={{ fontSize: 12 }}>{c.source}</span>
                    <div className="grow" />
                    <span className="dim" style={{ fontSize: 12 }}>score {c.score.toFixed(3)}</span>
                  </div>
                  <div style={{ fontSize: 13, color: "var(--text2)", lineHeight: 1.5 }}>
                    {c.content.slice(0, 200)}
                  </div>
                </div>
              ))}
            </>
          )}
        </div>
      )}
    </div>
  );
}
