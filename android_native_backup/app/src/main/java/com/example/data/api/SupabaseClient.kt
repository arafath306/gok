package com.example.data.api

import com.squareup.moshi.Moshi
import com.squareup.moshi.kotlin.reflect.KotlinJsonAdapterFactory
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.moshi.MoshiConverterFactory

object SupabaseClient {

    private const val BASE_URL = "https://ibesspeysnqikrzovmtm.supabase.co/"
    private const val ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImliZXNzcGV5c25xaWtyem92bXRtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODAzNzA4NDEsImV4cCI6MjA5NTk0Njg0MX0.BNGNubP-fAXEE-VZaFUCZe-jsOdEVR832OCFBj16m9Q"

    // Session variables (in-memory caching; can be backed by SharedPreferences in a production app)
    var accessToken: String? = null
    var currentUserId: String? = null

    private val moshi: Moshi = Moshi.Builder()
        .addLast(KotlinJsonAdapterFactory())
        .build()

    private val okHttpClient: OkHttpClient by lazy {
        val logging = HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        }

        OkHttpClient.Builder()
            .addInterceptor { chain ->
                val original = chain.request()
                
                // Dynamically build the Authorization header
                val token = accessToken ?: ANON_KEY
                
                val requestBuilder = original.newBuilder()
                    .header("apikey", ANON_KEY)
                    .header("Authorization", "Bearer $token")
                    .header("Content-Type", "application/json")
                
                chain.proceed(requestBuilder.build())
            }
            .addInterceptor(logging)
            .build()
    }

    val api: SupabaseApi by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(MoshiConverterFactory.create(moshi))
            .build()
            .create(SupabaseApi::class.java)
    }

    fun setSession(token: String, userId: String) {
        accessToken = token
        currentUserId = userId
    }

    fun clearSession() {
        accessToken = null
        currentUserId = null
    }
}
