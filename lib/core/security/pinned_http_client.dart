import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:http/io_client.dart';

class PinnedHttpClient extends IOClient {
  PinnedHttpClient() : super(
    HttpClient(context: SecurityContext(withTrustedRoots: false))
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        if (host.endsWith('supabase.co')) {
          final sha256Fingerprint = sha256.convert(cert.der).bytes;
          final fingerprint = sha256Fingerprint
              .map((b) => b.toRadixString(16).padLeft(2, '0'))
              .join(':')
              .toUpperCase();

          // Pinned fingerprints of the Supabase cert chain (leaf, intermediate, roots)
          const allowedFingerprints = {
            'E4:89:07:23:60:38:C7:FE:B0:5C:D8:62:E4:1C:D7:FC:57:28:F2:8D:A6:1B:95:E6:76:1D:9C:29:5C:5B:32:98', // Leaf
            '1D:FC:16:05:FB:AD:35:8D:8B:C8:44:F7:6D:15:20:3F:AC:9C:A5:C1:A7:9F:D4:85:7F:FA:F2:86:4F:BE:BF:96', // Let's Encrypt R11/R10/R3
            '76:B2:7B:80:A5:80:27:DC:3C:F1:DA:68:DA:C1:70:10:ED:93:99:7D:0B:60:3E:2F:AD:BE:85:01:24:93:B5:A7', // ISRG Root X1
            'EB:D4:10:40:E4:BB:3E:C7:42:C9:E3:81:D3:1E:F2:A4:1A:48:B6:68:5C:96:E7:CE:F3:C1:DF:6C:D4:33:1C:99', // Root cross-signature
          };

          return allowedFingerprints.contains(fingerprint);
        }
        return false; // Reject all untrusted certificates from other hosts
      }
  );
}
