package com.phucta.classroom.di

import com.phucta.classroom.data.local.ClassroomDatabase
import com.phucta.classroom.data.local.ClassroomPreferences
import com.phucta.classroom.data.local.TokenStorage
import com.phucta.classroom.data.remote.ClassroomApiService
import com.phucta.classroom.data.remote.GoogleOAuthManager
import com.phucta.classroom.data.repository.ClassroomRepository
import okhttp3.OkHttpClient
import org.koin.android.ext.koin.androidContext
import org.koin.dsl.module
import java.util.concurrent.TimeUnit

val appModule = module {
    single { ClassroomDatabase.getInstance(androidContext()) }
    single { ClassroomPreferences(androidContext()) }
    single { TokenStorage(androidContext()) }
    single {
        OkHttpClient.Builder()
            .connectTimeout(20, TimeUnit.SECONDS)
            .readTimeout(20, TimeUnit.SECONDS)
            .writeTimeout(20, TimeUnit.SECONDS)
            .build()
    }
    single { GoogleOAuthManager(androidContext(), get(), get(), get()) }
    single { ClassroomApiService(get()) }
    single { ClassroomRepository(androidContext(), get(), get(), get(), get()) }
}
