package com.example.ui.navigation

import androidx.compose.runtime.Composable
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import com.example.ui.screens.*

@Composable
fun AppNavigation(authViewModel: AuthViewModel = viewModel()) {
    val navController = rememberNavController()
    val startDestination = if (authViewModel.isUserSignedIn()) "main" else "onboarding"

    NavHost(navController = navController, startDestination = startDestination) {
        composable("onboarding") {
            OnboardingScreen(onFinish = {
                navController.navigate("auth") {
                    popUpTo("onboarding") { inclusive = true }
                }
            })
        }
        composable("auth") {
            AuthScreen(onLoginSuccess = {
                navController.navigate("main") {
                    popUpTo("auth") { inclusive = true }
                }
            })
        }
        composable("main") {
            MainScreen(
                onNavigateToCreate = { navController.navigate("create_thread") },
                onNavigateToChaStation = { }, // unused top level
                onNavigateToEditProfile = { navController.navigate("edit_profile") }
            )
        }
        composable("create_thread") {
            CreateThreadScreen(onBack = { navController.popBackStack() })
        }
        composable("edit_profile") {
            EditProfileScreen(onBack = { navController.popBackStack() })
        }
    }
}
