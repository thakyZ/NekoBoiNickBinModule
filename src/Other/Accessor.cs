using System;
using System.Collections;
using System.Collections.Generic;
using System.Linq;
using System.Management.Automation;
using System.Text.RegularExpressions;
using Microsoft.PowerShell.Commands;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;
using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Helpers;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Other;

/// <summary>
/// Borrowed from:
/// <see href="https://github.com/alx9r/ToolFoundations/blob/master/Functions/classAccessor.ps1"/>
/// </summary>
[CmdletBinding()]
[OutputType(typeof(string))]
public partial class GetAccessorPropertyNameCommand : PSCmdletBase {
  [Parameter(ValueFromPipeline = true)]
  public string String { get; set; }

  private string output { get; set; }
  [GeneratedRegex(@"\$(?!_)(?<PropertyName>\w*)\s*=\s*")]
  private static partial Regex UnderscoreCheckRegex();
  [GeneratedRegex(@"\$_(?<PropertyName>\w*)\s*=\s*")]
  private static partial Regex PropertyNameCaptureRegex();

  protected override void ProcessRecord() {
    // Check for missing underscore
    Match match = UnderscoreCheckRegex().Match(String);
    if (!match.Success) {
      throw new FormatException($"Missing underscore in property name at\n{String}");
    }

    // The main match
    match = PropertyNameCaptureRegex().Match(String);
    output = (ConvertFromRegexNamedGroupCaptureCommand.Invoke(match, PropertyNameCaptureRegex())).PropertyName;
  }

  protected override void EndProcessing() {
    this.WriteObject(output);
  }

  public static IEnumerable<T> Invoke<T>(string argument) {
    return new GetAccessorPropertyNameCommand() {
      String = argument,
    }.Invoke<T>();
  }
}

// cSpell:ignoreRegExp /"?(?:[A-Za-z0-9+/]{4})*("\r?\n\s*\+ ")?(?:[A-Za-z0-9+/]{2}==|[A-Za-z0-9+/]{3}=)?"?/

/// <summary>
/// Borrowed from:
/// <see href="https://github.com/alx9r/ToolFoundations/blob/master/Functions/classAccessor.ps1"/>
/// </summary>
[CmdletBinding()]
public class AccessorCommand : PSCmdletBase {
  // Specifies the object to access as a parent for the property.
  [Parameter(Mandatory = true,
             Position = 0,
             HelpMessage = "The object to access as a parent for the property.")]
  [ValidateNotNull]
  public object? Object { get; set; }

  // Specifies the script block containing the Get-Variable and Set-Variable accessors.
  [Parameter(Mandatory = true,
             Position = 1,
             HelpMessage = "The script block containing the Get-Variable and Set-Variable accessors.")]
  [ValidateNotNull]
  public ScriptBlock? Scriptblock { get; set; }

  private const string GetFunction = "ew0KICBQYXJhbSAoDQogICAgJFNjcmlwdGJsb2NrID0gKA0KICAgICAgIyBkZWZhdWx0IGdldHRlcg0KI"
                                   + "CAgICAgSW52b2tlLUV4cHJlc3Npb24gIntgJHRoaXMuXyQoYCRQcm9wZXJ0eU5hbWUpfSINCiAgICApDQ"
                                   + "ogICkNCiAgUmV0dXJuIE5ldy1PYmplY3QgIlN5c3RlbS5NYW5hZ2VtZW50LkF1dG9tYXRpb24uUFNPYmp"
                                   + "lY3QiIC1Qcm9wZXJ0eSBAeyBBY2Nlc3NvciA9ICdHZXQnOyBTY3JpcHRibG9jayA9ICRTY3JpcHRibG9j"
                                   + "ayB9DQp9";
  private const string SetFunction = "ew0KICBQYXJhbSAoDQogICAgJFNjcmlwdGJsb2NrID0gKA0KICAgICAgIyBkZWZhdWx0IHNldHRlcg0KI"
                                   + "CAgICAgSW52b2tlLUV4cHJlc3Npb24gIntQYXJhbShgJHApIGAkdGhpcy5fJCgkUHJvcGVydHlOYW1lKS"
                                   + "A9IGAkcH0iDQogICAgKQ0KICApDQogIFJldHVybiBOZXctT2JqZWN0ICJTeXN0ZW0uTWFuYWdlbWVudC5"
                                   + "BdXRvbWF0aW9uLlBTT2JqZWN0IiAtUHJvcGVydHkgQHsNCiAgICBBY2Nlc3NvciA9ICdTZXQnOyBTY3Jp"
                                   + "cHRibG9jayA9ICRTY3JpcHRibG9jaw0KICB9DQp9";

  public ScriptBlock? Getter { get; private set; }
  public ScriptBlock? Setter { get; private set; }
  public string PropertyName { get; }
  public Hashtable Functions { get; }
  public bool Done { get; private set; }

  protected AccessorCommand() {
    // Extract the property name
    PropertyName = GetAccessorPropertyNameCommand.Invoke<string>(this.MyInvocation.Line).FirstOrDefault("unknown");
    // Prepare the get and set functions that are invoked
    // inside the scriptblock passed to Accessor.
    Functions = new() {
      { "GetFunction", ScriptBlock.Create(GetFunction.ConvertFromBase64()) },
      { "SetFunction", ScriptBlock.Create(SetFunction.ConvertFromBase64()) },
    };
  }

  protected override void ProcessRecord() {
      // Prepare the variables that are available inside the
      // scriptblock that is passed to the accessor.
      // this = Object; // Ignore: PSAvoidAssignmentToAutomaticVariable
      //__PropertyName = //PropertyName
      var Variables = CmdletHelpers.GetVariable(["this", "__PropertyName"]);
      // Avoid a naming collision with the set and get aliases
      Done = false;
      List<ErrorRecord> errorRecords = [];
      try {
        CmdletHelpers.RemoveAlias(["Set"], scope: "Local");
      } catch {
        try {
          CmdletHelpers.RemoveItem([@"alias:\Set"]);
          Done = true;
        } catch(Exception exception) {
          errorRecords.Add(new ErrorRecord(exception, CmdletHelpers.GetErrorID(), ErrorCategory.InvalidOperation, nameof(ProcessRecord)));
        }
      } finally {
        if (!done) {
          foreach (ErrorRecord errorRecord in errorRecords) {
            this.WriteError(errorRecord);
          }
          this.Throw("Failed to remove Set alias.");
        }
      }
      CmdletHelpers.SetAlias("Set","SetFunction");
      CmdletHelpers.SetAlias("Setter","SetFunction");
      CmdletHelpers.SetAlias("Get","GetFunction");
      CmdletHelpers.SetAlias("Getter","GetFunction");

      // Invoke the scriptblock
      var items = this.MyInvocation.MyCommand.Module.NewBoundScriptBlock(this.Scriptblock).InvokeWithContext(functions, variables).Filter<Object>();

      this.Getter = ScriptBlock.Create("{}");

      ArrayList initialValue = new();
      foreach (var item in items) {
        // Get the initializer values
        if (!item.Accessor.ContainsAny(["Get", "Set"])) {
          initialValue.Add(item);
        }

        // Extract the getter
        if (item.Accessor == "Get") {
          Getter = item.Scriptblock;
        }

        // Extract the setter
        if (item.Accessor == "Set" ) {
          Setter = item.Scriptblock;
        }
      }

      // If there is no getter or setter don't add a ScriptProperty.
      if (Getter is null && Setter is null) {
        this.WriteObject(initialValue);
        return;
      }

      // Prepare to create the ScriptProperty.
      Hashtable Splat = new() {
        { "MemberType", "ScriptProperty" },
        { "Name"      , PropertyName },
        { "Value"     , Getter },
      };

      // Omit the setter parameter if it is null.
      if (Setter is not null) {
        Splat.Add("SecondValue", Setter);
      }

      // Add the accessors by creating a ScriptProperty.
      CmdletHelpers.AddMember(Object, [Splat]);

      // Return the initializers.
      this.WriteObject(initialValue);
      return;
  }
}
