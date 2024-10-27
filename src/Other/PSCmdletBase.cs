using System;
using System.Diagnostics.CodeAnalysis;
using System.Management.Automation;
using System.Runtime.Serialization;
using Microsoft.PowerShell.Commands;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

// ReSharper disable once InconsistentNaming
public abstract class PSCmdletBase : PSCmdlet, IDynamicParameters, ICustomCmdlet {
  public void WriteHost(object message, ConsoleColor? foregroundColor = null, ConsoleColor? backgroundColor = null, bool noNewLine = false) {
    WriteHostCommand command = new() {
      Object = message,
      ForegroundColor = foregroundColor ?? Console.ForegroundColor,
      BackgroundColor = backgroundColor ?? Console.BackgroundColor,
      NoNewline = noNewLine,
    };
    command.Invoke();
  }

  public virtual object? GetDynamicParameters() {
    return null;
  }

  [DoesNotReturn]
  public void Throw(ErrorRecord errorRecord) {
    this.ThrowTerminatingError(errorRecord);
  }

  [DoesNotReturn]
  public void Throw(ErrorRecord errorRecord, Exception replaceParentContainsErrorRecordException) {
    this.ThrowTerminatingError(new ErrorRecord(errorRecord, replaceParentContainsErrorRecordException));
    this.StopProcessing();
  }

  [DoesNotReturn]
  public void Throw(Exception exception, string? errorId, ErrorCategory errorCategory, object targetObject) {
    this.ThrowTerminatingError(new ErrorRecord(exception, errorId ?? CmdletHelpers.GetErrorID(2), errorCategory, targetObject));
    this.StopProcessing();
  }
}