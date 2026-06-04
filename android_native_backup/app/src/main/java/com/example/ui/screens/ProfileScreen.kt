package com.example.ui.screens

import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.FavoriteBorder
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.Send
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.rememberAsyncImagePainter
import com.example.domain.model.ThreadPost

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ProfileScreenContainer(
    onNavigateToEditProfile: () -> Unit,
    viewModel: ProfileViewModel = viewModel()
) {
    val profile by viewModel.profile.collectAsState()
    val threads by viewModel.myThreads.collectAsState()

    profile?.let { prof ->
        Scaffold { padding ->
            LazyColumn(
                modifier = Modifier
                    .padding(padding)
                    .fillMaxSize()
                    .background(Color.White)
            ) {
                // Header (Cover and Overlapping Profile Avatar)
                item {
                    Box(modifier = Modifier.fillMaxWidth().height(180.dp)) {
                        Image(
                            painter = rememberAsyncImagePainter(prof.coverUrl ?: "https://images.unsplash.com/photo-1596404886561-12cdce3fbe25"),
                            contentDescription = "Cover",
                            modifier = Modifier.fillMaxSize(),
                            contentScale = ContentScale.Crop
                        )
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            IconButton(
                                onClick = {},
                                modifier = Modifier
                                    .size(40.dp)
                                    .clip(CircleShape)
                                    .background(Color.White.copy(alpha = 0.85f))
                            ) {
                                Icon(
                                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                                    contentDescription = "Back",
                                    tint = Color.Black
                                )
                            }
                            IconButton(
                                onClick = onNavigateToEditProfile,
                                modifier = Modifier
                                    .size(40.dp)
                                    .clip(CircleShape)
                                    .background(Color.White.copy(alpha = 0.85f))
                            ) {
                                Icon(
                                    imageVector = Icons.Default.Settings,
                                    contentDescription = "Settings",
                                    tint = Color.Black
                                )
                            }
                        }
                    }
                    
                    // Avatar and Profile Details
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 24.dp)
                    ) {
                        // Overlapping Avatar with White border
                        Box(
                            modifier = Modifier
                                .offset(y = (-44).dp)
                                .size(88.dp)
                        ) {
                            Image(
                                painter = rememberAsyncImagePainter(prof.avatarUrl ?: "https://i.pravatar.cc/150"),
                                contentDescription = "Avatar",
                                modifier = Modifier
                                    .fillMaxSize()
                                    .border(4.dp, Color.White, CircleShape)
                                    .clip(CircleShape)
                                    .background(Color.White),
                                contentScale = ContentScale.Crop
                            )
                        }

                        // Text fields exactly positioned matching Flutter layout
                        Column(modifier = Modifier.offset(y = (-36).dp)) {
                            // Full Name
                            Text(
                                text = prof.fullName,
                                fontSize = 24.sp,
                                fontWeight = FontWeight.Bold,
                                color = Color.Black
                            )
                            Spacer(modifier = Modifier.height(2.dp))
                            
                            // Username in beautiful teal color
                            Text(
                                text = "@${prof.username}",
                                fontSize = 16.sp,
                                color = Color(0xFF1E824C), // Teal/Green accent color
                                fontWeight = FontWeight.Medium
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            // Bio
                            Text(
                                text = prof.bio ?: "কোন বায়ো নেই",
                                fontSize = 15.sp,
                                color = Color.DarkGray
                            )
                            
                            Spacer(modifier = Modifier.height(16.dp))
                            
                            // Center-aligned single number stats row
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                modifier = Modifier.fillMaxWidth()
                            ) {
                                Text(
                                    text = "${prof.followersCount}",
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 20.sp,
                                    color = Color.Black
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text("অনুসারী", fontSize = 14.sp, color = Color.Gray, fontWeight = FontWeight.Medium)
                                    Text("অনুসরণ", fontSize = 14.sp, color = Color.Gray, fontWeight = FontWeight.Medium)
                                    Text("আড্ডা মিটার", fontSize = 14.sp, color = Color.Gray, fontWeight = FontWeight.Medium)
                                }
                            }
                        }
                    }
                }
                
                // Navigation Tabs precisely designed (Pill coral select button)
                item {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 24.dp)
                            .offset(y = (-20).dp),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Selected Tab 1: Pill Button
                        Box(
                            modifier = Modifier
                                .clip(RoundedCornerShape(12.dp))
                                .background(Color(0xFFFDD4D6)) // Light Pink/Coral background
                                .padding(horizontal = 20.dp, vertical = 10.dp)
                        ) {
                            Text(
                                text = "আমার ডাক",
                                color = Color(0xFFE91E63), // Pink accent text
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp
                            )
                        }

                        // Tab 2
                        Box(
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        ) {
                            Text(
                                text = "উত্তর",
                                color = Color.Gray,
                                fontWeight = FontWeight.Medium,
                                fontSize = 14.sp
                            )
                        }

                        // Tab 3
                        Box(
                            modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                        ) {
                            Text(
                                text = "পছন্দ",
                                color = Color.Gray,
                                fontWeight = FontWeight.Medium,
                                fontSize = 14.sp
                            )
                        }
                    }
                    HorizontalDivider(modifier = Modifier.offset(y = (-10).dp), color = Color(0xFFF0F0F0))
                }
                
                // Thread Posts
                items(threads) { thread ->
                    CustomThreadItem(
                        post = thread,
                        onLikeToggle = {
                            viewModel.toggleLike(thread.id, !thread.isLikedByMe)
                        }
                    )
                    HorizontalDivider(color = Color(0xFFF0F0F0))
                }
            }
        }
    }
}

@Composable
fun CustomThreadItem(post: ThreadPost, onLikeToggle: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 16.dp)
    ) {
        Row(verticalAlignment = Alignment.Top) {
            Image(
                painter = rememberAsyncImagePainter(post.author.avatarUrl ?: "https://i.pravatar.cc/150"),
                contentDescription = "Avatar",
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape),
                contentScale = ContentScale.Crop
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column(modifier = Modifier.weight(1f)) {
                // Header (Name & Time + Menu on right)
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = post.author.fullName,
                            fontWeight = FontWeight.Bold,
                            fontSize = 16.sp,
                            color = Color.Black
                        )
                        Spacer(modifier = Modifier.height(2.dp))
                        Text(
                            text = post.createdAt,
                            fontSize = 12.sp,
                            color = Color.Gray
                        )
                    }
                    Icon(
                        imageVector = Icons.Default.MoreHoriz,
                        contentDescription = "Menu",
                        tint = Color.LightGray
                    )
                }
                
                Spacer(modifier = Modifier.height(10.dp))
                
                // Thread Text Content
                Text(
                    text = post.content,
                    fontSize = 15.sp,
                    color = Color.Black
                )

                if (post.imageUrls?.isNotEmpty() == true) {
                    Spacer(modifier = Modifier.height(12.dp))
                    Image(
                        painter = rememberAsyncImagePainter(post.imageUrls.first()),
                        contentDescription = "Post Image",
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(200.dp)
                            .clip(RoundedCornerShape(12.dp)),
                        contentScale = ContentScale.Crop
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))
                
                // Action Buttons exactly aligned
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Likes Icon & text
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier.clickable { onLikeToggle() }
                        ) {
                            Icon(
                                imageVector = if (post.isLikedByMe) Icons.Default.Favorite else Icons.Default.FavoriteBorder,
                                contentDescription = "Like",
                                tint = if (post.isLikedByMe) Color.Red else Color.Gray,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = if (post.likesCount > 0) post.likesCount.toString() else "[likes]",
                                color = Color.Gray,
                                fontSize = 13.sp
                            )
                        }

                        // Replies Icon & text
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                imageVector = Icons.Outlined.ChatBubbleOutline,
                                contentDescription = "Replies",
                                tint = Color.Gray,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(6.dp))
                            Text(
                                text = if (post.repliesCount > 0) post.repliesCount.toString() else "[replies]",
                                color = Color.Gray,
                                fontSize = 13.sp
                            )
                        }
                    }
                    
                    // Teal Paper Plane send icon on the right
                    Icon(
                        imageVector = Icons.Default.Send,
                        contentDescription = "Send",
                        tint = Color(0xFF1E824C), // Teal/Green accent plane
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }
    }
}
