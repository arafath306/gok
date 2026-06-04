package com.example.ui.screens

import android.widget.Toast
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AlternateEmail
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.DeleteForever
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import coil.compose.rememberAsyncImagePainter

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditProfileScreen(
    onBack: () -> Unit,
    profileViewModel: ProfileViewModel = viewModel()
) {
    val profile by profileViewModel.profile.collectAsState()
    val context = LocalContext.current

    var fullName by remember { mutableStateOf("") }
    var username by remember { mutableStateOf("") }
    var bio by remember { mutableStateOf("") }

    // Synchronize initial values once profile is loaded
    LaunchedEffect(profile) {
        profile?.let {
            fullName = it.fullName
            username = it.username
            bio = it.bio ?: ""
        }
    }

    val LabelRow: @Composable (String) -> Unit = { text ->
        Row {
            Text(text, fontWeight = FontWeight.Bold)
            Text(" *", color = MaterialTheme.colorScheme.error)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("প্রোফাইল এডিট", fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                actions = {
                    Button(
                        onClick = {
                            if (fullName.isNotBlank() && username.isNotBlank()) {
                                profileViewModel.updateProfile(fullName, username, bio) {
                                    Toast.makeText(context, "প্রোফাইল সফলভাবে আপডেট হয়েছে", Toast.LENGTH_SHORT).show()
                                    onBack()
                                }
                            } else {
                                Toast.makeText(context, "নাম এবং ব্যবহারকারীর নাম আবশ্যক", Toast.LENGTH_SHORT).show()
                            }
                        },
                        modifier = Modifier.padding(end = 8.dp).height(36.dp),
                        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 0.dp),
                        shape = RoundedCornerShape(8.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                    ) {
                        Text("সংরক্ষণ", fontWeight = FontWeight.Bold, color = MaterialTheme.colorScheme.onPrimary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = Color.White)
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .padding(padding)
                .fillMaxSize()
                .background(Color.White)
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            // Avatar
            Box(
                modifier = Modifier.fillMaxWidth(),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Box {
                        Image(
                            painter = rememberAsyncImagePainter(profile?.avatarUrl ?: "https://i.pravatar.cc/150"),
                            contentDescription = "Avatar",
                            modifier = Modifier
                                .size(100.dp)
                                .clip(CircleShape)
                                .border(2.dp, MaterialTheme.colorScheme.primary, CircleShape),
                            contentScale = ContentScale.Crop
                        )
                        Surface(
                            modifier = Modifier
                                .align(Alignment.BottomEnd)
                                .offset(x = (-4).dp, y = (-4).dp)
                                .size(32.dp),
                            shape = CircleShape,
                            color = MaterialTheme.colorScheme.primary,
                            onClick = { /* TODO */ }
                        ) {
                            Icon(
                                Icons.Filled.CameraAlt,
                                contentDescription = "Change photo",
                                modifier = Modifier.padding(6.dp),
                                tint = MaterialTheme.colorScheme.onPrimary
                            )
                        }
                    }
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        "ছবি পরিবর্তন করুন",
                        color = MaterialTheme.colorScheme.primary,
                        fontWeight = FontWeight.Bold,
                        style = MaterialTheme.typography.bodyMedium
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Full Name
            LabelRow("পুরো নাম")
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = fullName,
                onValueChange = { fullName = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("আপনার পুরো নাম লিখুন") },
                leadingIcon = { Icon(Icons.Filled.Person, contentDescription = null) },
                shape = RoundedCornerShape(8.dp)
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Username
            LabelRow("ব্যবহারকারীর নাম (Username)")
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = username,
                onValueChange = { username = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("username") },
                leadingIcon = { Icon(Icons.Filled.AlternateEmail, contentDescription = null) },
                shape = RoundedCornerShape(8.dp),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Ascii)
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Bio
            LabelRow("বায়ো (Bio)")
            Spacer(modifier = Modifier.height(8.dp))
            OutlinedTextField(
                value = bio,
                onValueChange = { bio = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = { Text("আপনার বায়ো লিখুন") },
                leadingIcon = { Icon(Icons.Filled.Edit, contentDescription = null) },
                shape = RoundedCornerShape(8.dp)
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Cover Photo
            LabelRow("কভার ফটো")
            Spacer(modifier = Modifier.height(8.dp))
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(150.dp)
                    .clip(RoundedCornerShape(8.dp)),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    painter = rememberAsyncImagePainter(profile?.coverUrl ?: "https://images.unsplash.com/photo-1596404886561-12cdce3fbe25"),
                    contentDescription = "Cover",
                    modifier = Modifier.fillMaxSize(),
                    contentScale = ContentScale.Crop
                )
                Surface(
                    color = MaterialTheme.colorScheme.surface.copy(alpha = 0.8f),
                    shape = RoundedCornerShape(16.dp),
                    onClick = { /* TODO */ }
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(Icons.Filled.Edit, contentDescription = null, modifier = Modifier.size(16.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("পরিবর্তন", fontWeight = FontWeight.Bold, style = MaterialTheme.typography.bodyMedium)
                    }
                }
            }

            Spacer(modifier = Modifier.height(48.dp))
            HorizontalDivider(color = MaterialTheme.colorScheme.outlineVariant)
            Spacer(modifier = Modifier.height(24.dp))
            
            // Delete Account / Log Out
            OutlinedButton(
                onClick = { /* TODO */ },
                modifier = Modifier.fillMaxWidth().height(48.dp),
                shape = RoundedCornerShape(8.dp),
                colors = ButtonDefaults.outlinedButtonColors(containerColor = MaterialTheme.colorScheme.errorContainer.copy(alpha=0.3f), contentColor = MaterialTheme.colorScheme.error),
                border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.error)
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(Icons.Filled.DeleteForever, contentDescription = null)
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("অ্যাকাউন্ট মুছুন", fontWeight = FontWeight.Bold)
                }
            }
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}
