using System;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using System.Management.Automation;
using System.Security.Cryptography;
using System.Security.Cryptography.X509Certificates;

using Microsoft.PowerShell.Commands;

using NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Extensions;

namespace NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Commands;

[SuppressMessage("ReSharper", "UnusedType.Global")]
[Cmdlet(VerbsCommunications.Write, "Signature")]
public class WriteSignatureCommand : Cmdlet {
  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  [Parameter(Mandatory = true,
             Position = 0,
             ValueFromPipeline = true,
             HelpMessage = "File to add the signature to.")]
  [ValidateNotNullOrEmpty]
  [Alias("PSPath","Path")]
  public string[]? FilePath {
    get { return _file; }
    set { _file = value; }
  }
  private string[]? _file;

  [SuppressMessage("ReSharper", "UnusedMember.Global")]
  [Parameter(Mandatory = false,
    Position = 1,
    HelpMessage = "Optional certificate to sign with.")]
  public X509Certificate2? Certificate {
    get { return _certificate; }
    set { _certificate = value; }
  }
  private X509Certificate2? _certificate;

  protected override void ProcessRecord() {
    X509Certificate2? cert = null;

    if (this._certificate is null) {
      var gciOut = new GetChildItemCommand { Path = [@"cert:\CurrentUser\My"] }.Invoke();
      cert = gciOut.OfType<X509Certificate2>().FirstOrDefault(GetCodeSigningCert);
    }

    if (cert is null && this._certificate is null) {
      this.ThrowTerminatingError(new ErrorRecord(new NullReferenceException("No Code Signing Certificate found, or specified."), "NullReferenceException,NekoBoiNick.CSharp.PowerShell.SoupCatUtils.Cmdlets.WriteSignatureCmdlet.", ErrorCategory.InvalidArgument, cert));
    }

    _ = new SetAuthenticodeSignatureCommand { FilePath = this._file, Certificate = cert }.Invoke();
  }

  private static bool GetCodeSigningCert(X509Certificate2? cert) {
    return cert?.Extensions
      .Where((X509Extension ext) => ext.Oid?.Value == "2.5.29.37" && ext is X509EnhancedKeyUsageExtension)
      .Cast<X509EnhancedKeyUsageExtension>()
      .Any((X509EnhancedKeyUsageExtension ext) =>
        ext.EnhancedKeyUsages
          .ToListObject()
          .Cast<Oid>()
          .Any((Oid oid) =>
            oid.FriendlyName?.Equals("Code Signing", StringComparison.OrdinalIgnoreCase) == true)) == true;
  }
}