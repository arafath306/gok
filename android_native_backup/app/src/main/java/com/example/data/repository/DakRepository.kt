package com.example.data.repository

import com.example.data.api.*
import com.example.domain.model.Notification
import com.example.domain.model.Profile
import com.example.domain.model.ThreadPost
import com.google.android.gms.tasks.Task
import com.google.firebase.auth.FirebaseAuth
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.UUID
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

// Extension to await Firebase Tasks in a coroutine context cleanly
suspend fun <T> Task<T>.await(): T = suspendCancellableCoroutine { cont ->
    addOnCompleteListener { task ->
        if (task.isSuccessful) {
            cont.resume(task.result)
        } else {
            cont.resumeWithException(task.exception ?: RuntimeException("Firebase operation failed"))
        }
    }
}

class DakRepository {

    private val auth = FirebaseAuth.getInstance()

    // Helper functions to map DTOs to Domain models
    private fun ProfileDto.toDomain(): Profile {
        return Profile(
            id = id,
            username = username ?: "anonymous",
            fullName = fullName ?: "Anonymous User",
            bio = bio,
            avatarUrl = avatarUrl,
            coverUrl = coverUrl,
            followersCount = followersCount,
            followingCount = followingCount
        )
    }

    private fun ThreadDto.toDomain(currentUid: String): ThreadPost {
        return ThreadPost(
            id = id ?: "",
            userId = userId,
            author = author?.toDomain() ?: Profile(userId, "unknown", "Unknown User", null, null, null, 0, 0),
            content = content,
            imageUrls = imageUrls,
            likesCount = likesCount,
            repliesCount = repliesCount,
            repostsCount = repostsCount,
            createdAt = createdAt ?: "এখনই",
            isLikedByMe = false
        )
    }

    // --- Authentication ---

    suspend fun signUp(email: String, password: String): Result<Boolean> {
        return try {
            val firebaseResult = auth.createUserWithEmailAndPassword(email, password).await()
            val firebaseUid = firebaseResult.user?.uid ?: throw Exception("Firebase registration failed")
            
            // Parallel login/signup in Supabase
            try {
                val response = SupabaseClient.api.signUp(SupabaseAuthRequest(email, password))
                if (response.isSuccessful && response.body() != null) {
                    val body = response.body()!!
                    val supabaseUid = body.user?.id ?: firebaseUid
                    SupabaseClient.setSession(body.accessToken, supabaseUid)
                    
                    // Create user profile in profiles table
                    val defaultUsername = email.substringBefore("@")
                    val profileDto = ProfileDto(
                        id = supabaseUid,
                        username = defaultUsername,
                        fullName = defaultUsername.replaceFirstChar { it.uppercase() },
                        bio = "আসসালামু আলাইকুম! আমি ডাক অ্যাপ ব্যবহার করছি।",
                        avatarUrl = "https://i.pravatar.cc/150?u=$supabaseUid",
                        coverUrl = "https://images.unsplash.com/photo-1596404886561-12cdce3fbe25"
                    )
                    SupabaseClient.api.upsertProfile(profileDto)
                }
            } catch (e: Exception) {
                // If Supabase fails but Firebase succeeds, we still log in to Firebase
                e.printStackTrace()
            }
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun signIn(email: String, password: String): Result<Boolean> {
        return try {
            val firebaseResult = auth.signInWithEmailAndPassword(email, password).await()
            val firebaseUid = firebaseResult.user?.uid ?: throw Exception("Firebase login failed")
            
            // Session synchronization with Supabase GoTrue
            try {
                val response = SupabaseClient.api.signIn(request = SupabaseAuthRequest(email, password))
                if (response.isSuccessful && response.body() != null) {
                    val body = response.body()!!
                    val supabaseUid = body.user?.id ?: firebaseUid
                    SupabaseClient.setSession(body.accessToken, supabaseUid)
                    
                    // Verify if user exists in the custom profiles table, otherwise upsert it
                    val profiles = SupabaseClient.api.getProfiles(idFilter = "eq.$supabaseUid")
                    if (profiles.isEmpty()) {
                        val defaultUsername = email.substringBefore("@")
                        val profileDto = ProfileDto(
                            id = supabaseUid,
                            username = defaultUsername,
                            fullName = defaultUsername.replaceFirstChar { it.uppercase() },
                            bio = "আসসালামু আলাইকুম! আমি ডাক অ্যাপ ব্যবহার করছি।",
                            avatarUrl = "https://i.pravatar.cc/150?u=$supabaseUid",
                            coverUrl = "https://images.unsplash.com/photo-1596404886561-12cdce3fbe25"
                        )
                        SupabaseClient.api.upsertProfile(profileDto)
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            Result.success(true)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    fun signOut() {
        auth.signOut()
        SupabaseClient.clearSession()
    }

    fun isUserSignedIn(): Boolean {
        return auth.currentUser != null
    }

    // --- Database Operations ---

    fun getFeed(): Flow<List<ThreadPost>> = flow {
        while (true) {
            try {
                val currentUid = SupabaseClient.currentUserId ?: auth.currentUser?.uid ?: ""
                val threads = SupabaseClient.api.getThreads()
                
                // Fetch the current user's liked thread IDs to compute isLikedByMe state
                val likedThreadIds = if (currentUid.isNotEmpty()) {
                    SupabaseClient.api.getLikes(userIdFilter = "eq.$currentUid").map { it.threadId }.toSet()
                } else emptySet()

                val domainThreads = threads.map { dto ->
                    dto.toDomain(currentUid).copy(
                        isLikedByMe = likedThreadIds.contains(dto.id)
                    )
                }
                emit(domainThreads)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            delay(5000) // Poll every 5 seconds for updates
        }
    }.flowOn(Dispatchers.IO)

    fun getChaStationFeed(): Flow<List<ThreadPost>> = getFeed().map { list ->
        list.filter { it.imageUrls?.isNotEmpty() == true }
    }

    suspend fun createThread(content: String, imageUrls: List<String>?) {
        val currentUid = SupabaseClient.currentUserId ?: auth.currentUser?.uid ?: return
        try {
            val threadDto = ThreadDto(
                userId = currentUid,
                content = content,
                imageUrls = imageUrls
            )
            SupabaseClient.api.createThread(threadDto)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    fun getNotifications(): Flow<List<Notification>> = flow {
        while (true) {
            try {
                val currentUid = SupabaseClient.currentUserId ?: auth.currentUser?.uid ?: ""
                val profiles = SupabaseClient.api.getProfiles()
                val actors = profiles.filter { it.id != currentUid }
                
                // Emulate dynamic notifications based on real profiles in Supabase
                val list = actors.take(3).mapIndexed { index, actor ->
                    val type = when (index) {
                        0 -> "FOLLOW"
                        1 -> "MENTION"
                        else -> "LIKE"
                    }
                    val msg = when (type) {
                        "FOLLOW" -> "আপনাকে অনুসরণ করা শুরু করেছেন"
                        "MENTION" -> "আপনাকে মেনশন করেছেন"
                        else -> "আপনার পোস্টে লাইক দিয়েছেন"
                    }
                    Notification(
                        id = "n_$index",
                        userId = currentUid,
                        actor = actor.toDomain(),
                        type = type,
                        threadId = null,
                        content = msg,
                        createdAt = "${index + 1} ঘণ্টা আগে",
                        read = index > 1
                    )
                }
                emit(list)
            } catch (e: Exception) {
                e.printStackTrace()
            }
            delay(10000)
        }
    }.flowOn(Dispatchers.IO)

    fun getCurrentProfile(): Flow<Profile> = flow {
        while (true) {
            try {
                val currentUid = SupabaseClient.currentUserId ?: auth.currentUser?.uid ?: ""
                if (currentUid.isNotEmpty()) {
                    val profiles = SupabaseClient.api.getProfiles(idFilter = "eq.$currentUid")
                    if (profiles.isNotEmpty()) {
                        emit(profiles.first().toDomain())
                    }
                }
            } catch (e: Exception) {
                e.printStackTrace()
            }
            delay(3000)
        }
    }.flowOn(Dispatchers.IO)

    fun getMyThreads(): Flow<List<ThreadPost>> = getFeed().map { list ->
        val currentUid = SupabaseClient.currentUserId ?: auth.currentUser?.uid ?: ""
        list.filter { it.userId == currentUid }
    }

    // Likes mutation
    suspend fun toggleLike(threadId: String, isLiked: Boolean) {
        val currentUid = SupabaseClient.currentUserId ?: auth.currentUser?.uid ?: return
        try {
            if (isLiked) {
                SupabaseClient.api.createLike(LikeDto(userId = currentUid, threadId = threadId))
            } else {
                SupabaseClient.api.deleteLike(userIdFilter = "eq.$currentUid", threadIdFilter = "eq.$threadId")
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    // Update Profile mutation
    suspend fun updateProfile(fullName: String, username: String, bio: String) {
        val currentUid = SupabaseClient.currentUserId ?: auth.currentUser?.uid ?: return
        try {
            val updates = mapOf(
                "full_name" to fullName,
                "username" to username,
                "bio" to bio
            )
            SupabaseClient.api.updateProfile(idFilter = "eq.$currentUid", profileUpdates = updates)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
