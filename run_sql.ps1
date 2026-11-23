param([string]$SqlFile)
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class Cred2 {
  [DllImport("advapi32.dll", CharSet=CharSet.Unicode, SetLastError=true)]
  static extern bool CredRead(string target, int type, int flags, out IntPtr cred);
  [StructLayout(LayoutKind.Sequential)] public struct CREDENTIAL {
    public int Flags; public int Type; public IntPtr TargetName; public IntPtr Comment;
    public System.Runtime.InteropServices.ComTypes.FILETIME LastWritten;
    public int CredentialBlobSize; public IntPtr CredentialBlob;
    public int Persist; public int AttributeCount; public IntPtr Attributes;
    public IntPtr TargetAlias; public IntPtr UserName;
  }
  public static byte[] Read(string target) {
    IntPtr p; if (!CredRead(target, 1, 0, out p)) return null;
    CREDENTIAL c = (CREDENTIAL)Marshal.PtrToStructure(p, typeof(CREDENTIAL));
    byte[] b = new byte[c.CredentialBlobSize];
    Marshal.Copy(c.CredentialBlob, b, 0, c.CredentialBlobSize);
    CredFree(p); return b;
  }
  [DllImport("advapi32.dll")] static extern void CredFree(IntPtr p);
}
'@
$tok = [Text.Encoding]::UTF8.GetString([Cred2]::Read("Supabase CLI:supabase"))
$sql = [IO.File]::ReadAllText($SqlFile, [Text.Encoding]::UTF8)
$body = @{ query = $sql } | ConvertTo-Json -Compress
try {
  $r = Invoke-RestMethod -Method Post -Uri "https://api.supabase.com/v1/projects/rlhynigapsduxpyjikle/database/query" -Headers @{ Authorization = "Bearer $tok" } -ContentType "application/json" -Body $body -TimeoutSec 90
  $r | ConvertTo-Json -Depth 6
} catch {
  "HTTP ERR: $($_.Exception.Message)"
  if ($_.ErrorDetails) { $_.ErrorDetails.Message }
}
