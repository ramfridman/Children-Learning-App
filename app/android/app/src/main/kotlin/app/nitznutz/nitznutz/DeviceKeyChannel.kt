package app.nitznutz.nitznutz

import android.os.Handler
import android.os.Looper
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.security.KeyPairGenerator
import java.security.KeyStore
import java.security.Signature
import java.security.spec.ECGenParameterSpec
import java.util.concurrent.Executors

/**
 * The one piece of native key code. It keeps a non-exportable P-256 signing key in the Android
 * Keystore (StrongBox when the phone has it), attaches the server's challenge to the key's
 * attestation, and signs request strings. The private key never leaves the secure hardware, and
 * errors carry only a short code, never a message that could contain data.
 */
class DeviceKeyChannel : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "app.nitznutz/device_key"
        private const val ALIAS = "nitznutz_device_key"
        private const val PROVIDER = "AndroidKeyStore"
    }

    private val worker = Executors.newSingleThreadExecutor()
    private val main = Handler(Looper.getMainLooper())

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        worker.execute {
            try {
                val value: Any? = when (call.method) {
                    "createKey" -> createKey(requireBytes(call, "challenge"))
                    "sign" -> sign(requireBytes(call, "message"))
                    "hasKey" -> keyStore().containsAlias(ALIAS)
                    "deleteKey" -> {
                        keyStore().deleteEntry(ALIAS)
                        null
                    }
                    else -> {
                        main.post { result.notImplemented() }
                        return@execute
                    }
                }
                main.post { result.success(value) }
            } catch (e: BadArgs) {
                main.post { result.error("bad_args", null, null) }
            } catch (e: Exception) {
                main.post { result.error("key_error", e.javaClass.simpleName, null) }
            }
        }
    }

    private class BadArgs : Exception()

    private fun requireBytes(call: MethodCall, name: String): ByteArray =
        call.argument<ByteArray>(name)?.takeIf { it.isNotEmpty() && it.size <= 4096 } ?: throw BadArgs()

    private fun keyStore(): KeyStore = KeyStore.getInstance(PROVIDER).apply { load(null) }

    private fun spec(challenge: ByteArray, strongBox: Boolean): KeyGenParameterSpec {
        val b = KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_SIGN)
            .setAlgorithmParameterSpec(ECGenParameterSpec("secp256r1"))
            .setDigests(KeyProperties.DIGEST_SHA256)
            .setUserAuthenticationRequired(false)
            .setAttestationChallenge(challenge)
        if (strongBox) b.setIsStrongBoxBacked(true)
        return b.build()
    }

    private fun generate(challenge: ByteArray, strongBox: Boolean) {
        val gen = KeyPairGenerator.getInstance(KeyProperties.KEY_ALGORITHM_EC, PROVIDER)
        gen.initialize(spec(challenge, strongBox))
        gen.generateKeyPair()
    }

    private fun createKey(challenge: ByteArray): Map<String, Any> {
        val ks = keyStore()
        ks.deleteEntry(ALIAS)
        try {
            generate(challenge, strongBox = true)
        } catch (e: Exception) {
            // No StrongBox on this phone (or it refused): use the normal secure hardware (TEE).
            ks.deleteEntry(ALIAS)
            generate(challenge, strongBox = false)
        }
        val chain = ks.getCertificateChain(ALIAS) ?: throw IllegalStateException("no chain")
        if (chain.size < 2) throw IllegalStateException("short chain")
        return mapOf(
            "publicKey" to chain[0].publicKey.encoded,
            "chain" to chain.map { it.encoded },
        )
    }

    private fun sign(message: ByteArray): ByteArray {
        val key = keyStore().getKey(ALIAS, null) as? java.security.PrivateKey ?: throw IllegalStateException("no key")
        val s = Signature.getInstance("SHA256withECDSA")
        s.initSign(key)
        s.update(message)
        return s.sign()
    }
}
