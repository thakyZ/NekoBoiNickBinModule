using System;
using System.Diagnostics.CodeAnalysis;
using System.Management.Automation;
using System.Runtime.Serialization;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

public interface ICustomCmdlet {
  [SuppressMessage("ReSharper", "UnusedMemberInSuper.Global")]
  [SuppressMessage("ReSharper", "UnusedParameter.Global")]
  public void WriteHost(object message, ConsoleColor? foregroundColor = null, ConsoleColor? backgroundColor = null, bool noNewLine = false);

  [DoesNotReturn]
  public void Throw(ErrorRecord errorRecord);

  [DoesNotReturn]
  public void Throw(ErrorRecord errorRecord, Exception replaceParentContainsErrorRecordException);

  [DoesNotReturn]
  public void Throw(Exception exception, string errorId, ErrorCategory errorCategory, object targetObject);
}