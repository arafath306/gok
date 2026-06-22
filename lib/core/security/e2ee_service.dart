import 'dart:convert';
import 'package:cryptography/cryptography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

class E2EEMessageResult {
  final String cipherTextBase64;
  final String nonceBase64;
  final String macBase64;

  E2EEMessageResult({
    required this.cipherTextBase64,
    required this.nonceBase64,
    required this.macBase64,
  });
}

class E2EEService {
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final sb.SupabaseClient _supabaseClient;
  
  // Algorithms
  final _keyExchangeAlgorithm = X25519();
  final _cipherAlgorithm = AesGcm.with256bits();

  E2EEService(this._supabaseClient);

  String get _currentUid => _supabaseClient.auth.currentUser?.id ?? '';
  String _privateKeyKey(String uid) => 'e2ee_private_key_$uid';

  /// Initializes the key pair for the current user.
  /// If a key pair already exists in secure storage, returns the public key (base64).
  /// If not, generates a new one, saves the private key, uploads the public key to Supabase,
  /// and returns the new public key.
  Future<String?> initializeKeys() async {
    if (_currentUid.isEmpty) return null;

    final existingPrivateKeyBase64 = await _secureStorage.read(key: _privateKeyKey(_currentUid));
    
    if (existingPrivateKeyBase64 != null) {
      // Reconstruct keypair to get public key
      final privateKeyBytes = base64Decode(existingPrivateKeyBase64);
      final keyPair = await _keyExchangeAlgorithm.newKeyPairFromSeed(privateKeyBytes);
      final publicKey = await keyPair.extractPublicKey();
      return base64Encode(publicKey.bytes);
    }

    // Generate new key pair
    final keyPair = await _keyExchangeAlgorithm.newKeyPair();
    final privateKeyBytes = await keyPair.extractPrivateKeyBytes();
    final publicKey = await keyPair.extractPublicKey();

    final privateKeyBase64 = base64Encode(privateKeyBytes);
    final publicKeyBase64 = base64Encode(publicKey.bytes);

    // Save private key locally
    await _secureStorage.write(key: _privateKeyKey(_currentUid), value: privateKeyBase64);

    // Update public key in Supabase profile
    try {
      await _supabaseClient.from('profiles').update({'public_key': publicKeyBase64}).eq('id', _currentUid);
    } catch (e) {
      print('Error uploading public key: $e');
      // If we fail to upload, we should ideally revert the local storage, but for now we proceed.
    }

    return publicKeyBase64;
  }

  /// Encrypts a text message for a specific receiver using their public key.
  Future<E2EEMessageResult?> encryptMessage(String plainText, String receiverPublicKeyBase64) async {
    if (_currentUid.isEmpty || receiverPublicKeyBase64.isEmpty) return null;

    final privateKeyBase64 = await _secureStorage.read(key: _privateKeyKey(_currentUid));
    if (privateKeyBase64 == null) return null;

    final privateKeyBytes = base64Decode(privateKeyBase64);
    final keyPair = await _keyExchangeAlgorithm.newKeyPairFromSeed(privateKeyBytes);

    final receiverPublicKeyBytes = base64Decode(receiverPublicKeyBase64);
    final receiverPublicKey = SimplePublicKey(receiverPublicKeyBytes, type: KeyPairType.x25519);

    // Derive shared secret
    final sharedSecret = await _keyExchangeAlgorithm.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: receiverPublicKey,
    );

    // Encrypt
    final secretKeyBytes = await sharedSecret.extractBytes();
    final secretKey = SecretKey(secretKeyBytes);
    
    final nonce = _cipherAlgorithm.newNonce();
    
    final secretBox = await _cipherAlgorithm.encrypt(
      utf8.encode(plainText),
      secretKey: secretKey,
      nonce: nonce,
    );

    return E2EEMessageResult(
      cipherTextBase64: base64Encode(secretBox.cipherText),
      nonceBase64: base64Encode(secretBox.nonce),
      macBase64: base64Encode(secretBox.mac.bytes),
    );
  }

  /// Decrypts a received message using the sender's public key.
  Future<String?> decryptMessage(
    String cipherTextBase64, 
    String nonceBase64, 
    String macBase64, 
    String senderPublicKeyBase64
  ) async {
    if (_currentUid.isEmpty || senderPublicKeyBase64.isEmpty) return null;

    final privateKeyBase64 = await _secureStorage.read(key: _privateKeyKey(_currentUid));
    if (privateKeyBase64 == null) return null;

    final privateKeyBytes = base64Decode(privateKeyBase64);
    final keyPair = await _keyExchangeAlgorithm.newKeyPairFromSeed(privateKeyBytes);

    final senderPublicKeyBytes = base64Decode(senderPublicKeyBase64);
    final senderPublicKey = SimplePublicKey(senderPublicKeyBytes, type: KeyPairType.x25519);

    // Derive shared secret
    final sharedSecret = await _keyExchangeAlgorithm.sharedSecretKey(
      keyPair: keyPair,
      remotePublicKey: senderPublicKey,
    );

    // Decrypt
    final secretKeyBytes = await sharedSecret.extractBytes();
    final secretKey = SecretKey(secretKeyBytes);

    final secretBox = SecretBox(
      base64Decode(cipherTextBase64),
      nonce: base64Decode(nonceBase64),
      mac: Mac(base64Decode(macBase64)),
    );

    try {
      final plainTextBytes = await _cipherAlgorithm.decrypt(
        secretBox,
        secretKey: secretKey,
      );
      return utf8.decode(plainTextBytes);
    } catch (e) {
      print('Decryption failed: $e');
      return null; // Could not decrypt (e.g. wrong key, corrupted data)
    }
  }

  /// Logs out the user by removing their keys from local storage.
  Future<void> clearKeys() async {
    if (_currentUid.isNotEmpty) {
      await _secureStorage.delete(key: _privateKeyKey(_currentUid));
    }
  }
}
