using System;
using System.Collections.Generic;
using System.Diagnostics;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

internal class ProcessStdCapture : IDisposable {
  private readonly List<string> stdout = [];
  private readonly List<string> stderr = [];
  private readonly List<string> data = [];
  public IReadOnlyList<string> StdOut => stdout;
  public IReadOnlyList<string> StdErr => stderr;
  public IReadOnlyList<string> Data => data;

  private readonly Process process;
  private readonly bool capture;

  public ProcessStdCapture(Process process, bool capture) {
    this.capture = capture;
    this.process = process;
    this.process.OutputDataReceived += OutputDataReceived;
    this.process.Disposed += Disposed;
  }

  private void Disposed(object? sender, EventArgs e) {
    if (_isDisposed) {
      return;
    }

    this.Dispose();
  }

  internal void OutputDataReceived(object sender, DataReceivedEventArgs e) {
    if (_isDisposed) {
      return;
    }

    data.Add(e.Data ?? string.Empty);
  }

  internal void Write() {
    if (_isDisposed) {
      return;
    }

    var sOutput = this.process.StandardOutput;
    var sError = this.process.StandardError;

    if (this.capture) {
      stderr.Add(sOutput.ReadLine() ?? string.Empty);
    } else {
      Console.Error.Write(sError.ReadLine());
    }

    if (this.capture) {
      stdout.Add(sOutput.ReadLine() ?? string.Empty);
    } else {
      Console.Out.Write(sOutput.ReadLine());
    }
  }

  private bool _isDisposed;

  protected virtual void Dispose(bool disposing) {
    if (!_isDisposed) {
      this.stdout.Clear();
      this.stderr.Clear();
      this.data.Clear();
      try {
        this.process.OutputDataReceived -= OutputDataReceived;
        this.process.Disposed -= Disposed;
        this.process.Dispose();
      } catch {
        // Do nothing.
      }
      _isDisposed = true;
    }
  }

  ~ProcessStdCapture() {
    Dispose(false);
  }

  public void Dispose() {
    this.Dispose(true);
    GC.SuppressFinalize(this);
  }
}