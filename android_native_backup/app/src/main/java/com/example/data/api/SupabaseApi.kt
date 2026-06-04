package com.example.data.api

import com.squareup.moshi.Json
import com.squareup.moshi.JsonClass
import retrofit2.Response
import retrofit2.http.*

@JsonClass(generateAdapter = true)
data class SupabaseAuthRequest(
    val email: String,
    val password: String
)

@JsonClass(generateAdapter = true)
data class SupabaseUser(
    val id: String,
    val email: String?
)

@JsonClass(generateAdapter = true)
data class SupabaseAuthResponse(
    @Json(name = "access_token") val accessToken: String,
    @Json(name = "token_type") val tokenType: String?,
    @Json(name = "expires_in") val expiresIn: Long?,
    val user: SupabaseUser?
)

@JsonClass(generateAdapter = true)
data class ProfileDto(
    val id: String,
    val username: String?,
    @Json(name = "full_name") val fullName: String?,
    val bio: String?,
    @Json(name = "avatar_url") val avatarUrl: String?,
    @Json(name = "cover_url") val coverUrl: String?,
    @Json(name = "followers_count") val followersCount: Int = 0,
    @Json(name = "following_count") val followingCount: Int = 0,
    @Json(name = "created_at") val createdAt: String? = null
)

@JsonClass(generateAdapter = true)
data class ThreadDto(
    val id: String? = null,
    @Json(name = "user_id") val userId: String,
    val content: String,
    @Json(name = "image_urls") val imageUrls: List<String>?,
    @Json(name = "likes_count") val likesCount: Int = 0,
    @Json(name = "replies_count") val repliesCount: Int = 0,
    @Json(name = "reposts_count") val repostsCount: Int = 0,
    @Json(name = "is_quote") val isQuote: Boolean = false,
    @Json(name = "quoted_thread_id") val quotedThreadId: String? = null,
    @Json(name = "created_at") val createdAt: String? = null,
    @Json(name = "author") val author: ProfileDto? = null
)

@JsonClass(generateAdapter = true)
data class LikeDto(
    val id: String? = null,
    @Json(name = "user_id") val userId: String,
    @Json(name = "thread_id") val threadId: String
)

@JsonClass(generateAdapter = true)
data class FollowDto(
    val id: String? = null,
    @Json(name = "follower_id") val follower_id: String,
    @Json(name = "following_id") val following_id: String
)

@JsonClass(generateAdapter = true)
data class ReplyDto(
    val id: String? = null,
    @Json(name = "thread_id") val threadId: String,
    @Json(name = "user_id") val userId: String,
    val content: String,
    @Json(name = "image_url") val imageUrl: String? = null,
    @Json(name = "created_at") val createdAt: String? = null,
    @Json(name = "author") val author: ProfileDto? = null
)

interface SupabaseApi {

    // --- Authentication (GoTrue) ---
    @POST("auth/v1/signup")
    suspend fun signUp(
        @Body request: SupabaseAuthRequest
    ): Response<SupabaseAuthResponse>

    @POST("auth/v1/token")
    suspend fun signIn(
        @Query("grant_type") grantType: String = "password",
        @Body request: SupabaseAuthRequest
    ): Response<SupabaseAuthResponse>

    // --- Database (PostgREST) ---
    
    // Profiles
    @GET("rest/v1/profiles")
    suspend fun getProfiles(
        @Query("select") select: String = "*",
        @Query("id") idFilter: String? = null
    ): List<ProfileDto>

    @POST("rest/v1/profiles")
    suspend fun upsertProfile(
        @Body profile: ProfileDto,
        @Header("Prefer") prefer: String = "resolution=merge-duplicates,return=representation"
    ): List<ProfileDto>

    @PATCH("rest/v1/profiles")
    suspend fun updateProfile(
        @Query("id") idFilter: String,
        @Body profileUpdates: Map<String, String?>
    ): Response<Unit>

    // Threads
    @GET("rest/v1/threads")
    suspend fun getThreads(
        @Query("select") select: String = "*,author:user_id(*)",
        @Query("order") order: String = "created_at.desc",
        @Query("user_id") userIdFilter: String? = null
    ): List<ThreadDto>

    @POST("rest/v1/threads")
    suspend fun createThread(
        @Body thread: ThreadDto,
        @Header("Prefer") prefer: String = "return=representation"
    ): List<ThreadDto>

    // Likes
    @GET("rest/v1/likes")
    suspend fun getLikes(
        @Query("user_id") userIdFilter: String? = null,
        @Query("thread_id") threadIdFilter: String? = null
    ): List<LikeDto>

    @POST("rest/v1/likes")
    suspend fun createLike(
        @Body like: LikeDto
    ): Response<Unit>

    @DELETE("rest/v1/likes")
    suspend fun deleteLike(
        @Query("user_id") userIdFilter: String,
        @Query("thread_id") threadIdFilter: String
    ): Response<Unit>

    // Follows
    @GET("rest/v1/follows")
    suspend fun getFollows(
        @Query("follower_id") followerFilter: String? = null,
        @Query("following_id") followingFilter: String? = null
    ): List<FollowDto>

    @POST("rest/v1/follows")
    suspend fun createFollow(
        @Body follow: FollowDto
    ): Response<Unit>

    @DELETE("rest/v1/follows")
    suspend fun deleteFollow(
        @Query("follower_id") followerFilter: String,
        @Query("following_id") followingFilter: String
    ): Response<Unit>

    // Replies (Comments)
    @GET("rest/v1/replies")
    suspend fun getReplies(
        @Query("thread_id") threadIdFilter: String,
        @Query("select") select: String = "*,author:user_id(*)",
        @Query("order") order: String = "created_at.asc"
    ): List<ReplyDto>

    @POST("rest/v1/replies")
    suspend fun createReply(
        @Body reply: ReplyDto
    ): Response<Unit>
}
