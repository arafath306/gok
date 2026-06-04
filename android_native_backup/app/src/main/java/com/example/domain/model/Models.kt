package com.example.domain.model

data class Profile(
    val id: String,
    val username: String,
    val fullName: String,
    val bio: String?,
    val avatarUrl: String?,
    val coverUrl: String?,
    val followersCount: Int,
    val followingCount: Int
)

data class ThreadPost(
    val id: String,
    val userId: String,
    val author: Profile,
    val content: String,
    val imageUrls: List<String>?,
    val likesCount: Int,
    val repliesCount: Int,
    val repostsCount: Int,
    val createdAt: String,
    val isLikedByMe: Boolean = false
)

data class Notification(
    val id: String,
    val userId: String,
    val actor: Profile,
    val type: String, // "LIKE", "REPLY", "FOLLOW", "MENTION"
    val threadId: String?,
    val content: String,
    val createdAt: String,
    val read: Boolean
)
