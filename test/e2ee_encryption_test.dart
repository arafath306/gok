import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('End-to-End Encryption (E2EE) Cryptographic Verification', () {
    final keyExchangeAlgorithm = X25519();
    final cipherAlgorithm = AesGcm.with256bits();

    test('ECDH Key Exchange and AES-GCM-256 Encryption/Decryption flow', () async {
      // 1. Simulate Alice generating her key pair
      final aliceKeyPair = await keyExchangeAlgorithm.newKeyPair();
      final alicePublicKey = await aliceKeyPair.extractPublicKey();
      final alicePrivateKeyBytes = await aliceKeyPair.extractPrivateKeyBytes();

      // 2. Simulate Bob generating his key pair
      final bobKeyPair = await keyExchangeAlgorithm.newKeyPair();
      final bobPublicKey = await bobKeyPair.extractPublicKey();
      final bobPrivateKeyBytes = await bobKeyPair.extractPrivateKeyBytes();

      // Convert keys to formats that would be transmitted/stored (Base64)
      final alicePublicKeyBase64 = base64Encode(alicePublicKey.bytes);
      final bobPublicKeyBase64 = base64Encode(bobPublicKey.bytes);

      // Verify they are different
      expect(alicePublicKeyBase64, isNot(equals(bobPublicKeyBase64)));
      print('Alice Public Key: $alicePublicKeyBase64');
      print('Bob Public Key: $bobPublicKeyBase64');

      // 3. Alice wants to send a secret message to Bob
      const originalMessage = "Hello Bob! This is an end-to-end encrypted message 🤫";

      // Alice derives the shared secret key using Bob's public key & Alice's private key
      final aliceSharedSecret = await keyExchangeAlgorithm.sharedSecretKey(
        keyPair: aliceKeyPair,
        remotePublicKey: SimplePublicKey(base64Decode(bobPublicKeyBase64), type: KeyPairType.x25519),
      );
      final aliceSecretKeyBytes = await aliceSharedSecret.extractBytes();
      final aliceSecretKey = SecretKey(aliceSecretKeyBytes);

      // Alice encrypts the message using the derived secret key
      final nonce = cipherAlgorithm.newNonce();
      final secretBox = await cipherAlgorithm.encrypt(
        utf8.encode(originalMessage),
        secretKey: aliceSecretKey,
        nonce: nonce,
      );

      final cipherTextBase64 = base64Encode(secretBox.cipherText);
      final nonceBase64 = base64Encode(secretBox.nonce);
      final macBase64 = base64Encode(secretBox.mac.bytes);

      final dbFormattedMessage = 'E2EE:v1:$nonceBase64:$macBase64:$cipherTextBase64';

      print('Encrypted Message stored in DB: $dbFormattedMessage');
      expect(cipherTextBase64, isNot(contains("Hello Bob")));

      // 4. Bob receives the encrypted message.
      // Bob extracts the parts from the database formatted message
      final parts = dbFormattedMessage.split(':');
      expect(parts.length, 5);
      expect(parts[0], 'E2EE');
      expect(parts[1], 'v1');

      final receivedNonceBase64 = parts[2];
      final receivedMacBase64 = parts[3];
      final receivedCipherTextBase64 = parts[4];

      // Bob derives the same shared secret key using Alice's public key & Bob's private key
      final bobReconstructedPrivateKey = await keyExchangeAlgorithm.newKeyPairFromSeed(bobPrivateKeyBytes);
      final bobSharedSecret = await keyExchangeAlgorithm.sharedSecretKey(
        keyPair: bobReconstructedPrivateKey,
        remotePublicKey: SimplePublicKey(base64Decode(alicePublicKeyBase64), type: KeyPairType.x25519),
      );
      final bobSecretKeyBytes = await bobSharedSecret.extractBytes();
      final bobSecretKey = SecretKey(bobSecretKeyBytes);

      // Bob decrypts the message
      final receivedSecretBox = SecretBox(
        base64Decode(receivedCipherTextBase64),
        nonce: base64Decode(receivedNonceBase64),
        mac: Mac(base64Decode(receivedMacBase64)),
      );

      final decryptedBytes = await cipherAlgorithm.decrypt(
        receivedSecretBox,
        secretKey: bobSecretKey,
      );
      final decryptedMessage = utf8.decode(decryptedBytes);

      print('Decrypted Message by Bob: $decryptedMessage');
      expect(decryptedMessage, equals(originalMessage));
    });
  });
}
